//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

public protocol NINChatSessionProtocol {
    typealias NinchatSessionCompletion = (NINSessionCredentials?, Error?) -> Void

    /**
    * Append information to the user agent string. The string should be in
    * the form "app-name/version" or "app-name/version (more; details)".
    *
    * Set this prior to calling startWithCallback:
    */
    var appDetails: String? { get set }
    var session: NINResult<NINLowLevelClientSession?> { get }
    var delegate: NINChatSessionDelegate? { get set }
    var delegateSwiftUI: NinchatSwiftUIDelegate? { get set }

    init(configKey: String, queueID: String?, environments: [String]?, metadata: NINLowLevelClientProps?, configuration: NINSiteConfiguration?)
    func start(completion: @escaping NinchatSessionCompletion) throws
    func start(credentials: NINSessionCredentials, completion: @escaping NinchatSessionCompletion) throws
    func chatSession(within navigationController: UINavigationController?, useSwiftUI: Bool) throws -> UIViewController?
    func deallocate()
}
extension NINChatSessionProtocol {
    init(configKey: String, queueID: String?, environments: [String]?, metadata: NINLowLevelClientProps?) {
        self.init(configKey: configKey, queueID: queueID, environments: environments, metadata: metadata, configuration: nil)
    }
}

public final class NINChatSession: NINChatSessionProtocol, NINChatDevHelper {
    lazy var sessionManager: NINChatSessionManager! = {
        NINChatSessionManagerImpl(session: self.internalDelegate, serverAddress: self.defaultServerAddress, audienceMetadata: self.audienceMetadata, configuration: self.configuration)
    }()
    lazy var internalDelegate: InternalDelegate? = {
        InternalDelegate(session: self)
    }()
    lazy var internalSwiftUIDelegate: InternalSwiftUIDelegate? = {
        InternalSwiftUIDelegate(session: self)
    }()
    private lazy var coordinator: Coordinator? = {
        NINCoordinator(with: self.sessionManager, delegate: self.internalDelegate, delegateSwiftUI: self.internalSwiftUIDelegate) { [weak self] in
            self?.deallocate()
        }
    }()
    private let audienceMetadata: NINLowLevelClientProps?
    private let configuration: NINSiteConfiguration?
    private var configKey: String!
    private var queueID: String?
    private var environments: [String]?
    private var started: Bool! = false
    private var resumeMode: ResumeMode?
    private var sessionAlive: Bool! = false
    private var defaultServerAddress: String {
        #if NIN_USE_TEST_SERVER
            return Constants.kTestServerAddress.rawValue
        #else
            return Constants.kProductionServerAddress.rawValue
        #endif
    }

    // MARK: - NINChatDevHelper

    public var serverAddress: String! {
        set { self.sessionManager.serverAddress = newValue }
        get { self.sessionManager.serverAddress }
    }
    public var siteSecret: String? {
        set { self.sessionManager.siteSecret = newValue }
        get { self.sessionManager.siteSecret }
    }

    // MARK: - NINChatSessionProtocol

    public weak var delegate: NINChatSessionDelegate?
    public weak var delegateSwiftUI: NinchatSwiftUIDelegate?
    public var session: NINResult<NINLowLevelClientSession?> {
        guard self.started else { return .failure(NINExceptions.apiNotStarted) }
        return .success(self.sessionManager.session)
    }
    public var appDetails: String? {
        set { sessionManager.appDetails = newValue }
        get { sessionManager.appDetails }
    }

    required public init(configKey: String, queueID: String? = nil, environments: [String]? = nil, metadata: NINLowLevelClientProps? = nil, configuration: NINSiteConfiguration? = nil) {
        self.configKey = configKey
        self.queueID = queueID
        self.environments = environments
        self.audienceMetadata = metadata
        self.configuration = configuration
        self.serverAddress = Constants.kProductionServerAddress.rawValue
        self.started = false
    }

    deinit {
        self.deallocate()
    }

    /// Performs these steps:
    /// 1. Fetches the site configuration over a REST call
    /// 2. Using that configuration, starts a new chat session
    /// 3. Retrieves the queues available for this realm (realm id from site configuration)
    public func start(completion: @escaping NinchatSessionCompletion) throws {
        debugger("Starting a new chat session")
        do {
            try self.fetchSiteConfiguration { [weak self] error in
                DispatchQueue.main.async {
                    do {
                        try self?.openChatSession() { credentials, error in
                            guard let weakSelf = self, error == nil else { completion(credentials, error); return }

                            /// Prepare coordinator for starting
                            /// This is quite important to prepare time and memory consuming tasks before the user
                            /// starts the coordinator, otherwise he/she will face unexpected views
                            weakSelf.coordinator?.prepareNINQuestionnaireViewModel(audienceMetadata: weakSelf.audienceMetadata) {
                                completion(credentials, error)
                            }
                        }
                    } catch { completion(nil, error) }
                }
            }
        } catch { completion(nil, error) }
    }

    /**
     * Starts the API engine using given credentials. Must be called before other API methods.
     * If callback returns the error indicating invalidated credentials, the caller is responsible to decide
     * for using `start(completion:)` and starting a new chat session.
    */
    public func start(credentials: NINSessionCredentials, completion: @escaping NinchatSessionCompletion) throws {
        debugger("Trying to continue given chat session")
        do {
            try self.fetchSiteConfiguration { [weak self] error in
                DispatchQueue.main.async {
                    do {
                        try self?.openChatSession(credentials: credentials) { credentials, error in
                            guard let weakSelf = self, error == nil else { completion(credentials, error); return }

                            /// Prepare coordinator for starting
                            /// This is quite important to prepare time and memory consuming tasks before the user
                            /// starts the coordinator, otherwise he/she will face unexpected views
                            weakSelf.coordinator?.prepareNINQuestionnaireViewModel(audienceMetadata: weakSelf.audienceMetadata) {
                                completion(credentials, error)
                            }
                        }
                    } catch { completion(nil, error) }
                }
            }
        } catch { completion(nil, error) }
    }

    public func chatSession(within navigationController: UINavigationController?, useSwiftUI: Bool = false) throws -> UIViewController? {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        guard self.started else { throw NINExceptions.apiNotStarted }
        guard !self.sessionAlive else { throw NINExceptions.apiAlive }

        self.sessionAlive = true
        /// use "audienceAutoQueue" if queue is an empty (not null) string
        if self.queueID?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            self.queueID = self.sessionManager.siteConfiguration.audienceAutoQueue
        }
        return coordinator?.start(with: self.queueID?.trimmingCharacters(in: .whitespacesAndNewlines),
                                  resume: self.resumeMode, within: navigationController, useSwiftUI: useSwiftUI)
    }

    public func deallocate() {
        guard !Thread.current.isRunningXCTests else { return }

        URLSession.shared.invalidateAndCancel()
        self.coordinator?.deallocate()
        self.sessionManager?.deallocateSession()
        self.sessionManager = nil
        self.started = false
        self.sessionAlive = false
        self.internalDelegate?.onDidEnd()
    }
}

// MARK: - Private helper methods

/// Shared helper
extension NINChatSession {
    private func fetchSiteConfiguration(completion: @escaping (Error?) -> Void) throws {
        sessionManager.fetchSiteConfiguration(config: configKey, environments: environments) { error in
            completion(error)
        }
    }

    private func listAllQueues(credentials: NINSessionCredentials?, resumeMode: ResumeMode?, completion: @escaping NinchatSessionCompletion) throws {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        var allQueues = sessionManager.siteConfiguration.audienceQueues ?? []

        /// describe_queue for the injected queue
        if let queue = queueID?.trimmingCharacters(in: .whitespacesAndNewlines),
           queue.count > 0 {
            allQueues.append(queue)
        }
        /// describe_queue for "audienceAutoQueue"
        if let autoQueue = self.sessionManager.siteConfiguration.audienceAutoQueue?.trimmingCharacters(in: .whitespacesAndNewlines),
           autoQueue.count > 0, !allQueues.contains(autoQueue) {
            allQueues.append(autoQueue)
        }

        try sessionManager.list(queues: allQueues) { [weak self] error in
            self?.started = (error == nil)
            self?.resumeMode = resumeMode
            completion(credentials, error)
        }
    }
}

/// Fresh Session helpers
extension NINChatSession {
    private func openChatSession(completion: @escaping NinchatSessionCompletion) throws {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        try sessionManager.openSession { [weak self] credentials, canResume, error in
            guard error == nil else { completion(credentials, error); return }

            do {
                /// Find our realm's queues
                /// Potentially passing a nil queueIds here is intended
                try self?.listAllQueues(credentials: credentials, resumeMode: nil, completion: completion)
            } catch {
                completion(nil, error)
            }
        }
    }
}

/// Resuming Session helpers
extension NINChatSession {
    private func openChatSession(credentials: NINSessionCredentials, completion: @escaping NinchatSessionCompletion) throws {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        try sessionManager.continueSession(credentials: credentials) { [weak self] newCredential, resumeMode, error in
            self?.removePreviouslyOpenedSession(newCredential: newCredential, oldCredentials: credentials)
            if resumeMode == nil || error != nil {
                do { try self?.handleResumptionFailure(completion: completion) }
                catch { completion(nil, error) }

                return
            }

            self?.started = true
            self?.resumeMode = resumeMode
            completion(NINSessionCredentials(userID: credentials.userID, userAuth: credentials.userAuth, sessionID: newCredential?.sessionID), error)
        }
    }

    private func removePreviouslyOpenedSession(newCredential: NINSessionCredentials?, oldCredentials: NINSessionCredentials) {
        guard newCredential?.sessionID != oldCredentials.sessionID else { return }
        self.sessionManager.closeSession(credentials: oldCredentials, completion: nil)
    }

    private func handleResumptionFailure(completion: @escaping NinchatSessionCompletion) throws {
        if self.internalDelegate?.onResumeFailed() ?? false {
            /// Automatically start a new session
            try self.openChatSession(completion: completion)
        } else {
            /// Return an exception if session resumption failed and the app doesn't want to start a new session automatically
            throw NINSessionExceptions.sessionResumptionFailed
        }
    }
}
