//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

public protocol NINChatDevHelper {
    var serverAddress: String! { get set }
    var siteSecret: String? { get set }
}

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

    init(configKey: String, queueID: String?, environments: [String]?, metadata: NINLowLevelClientProps?, configuration: NINSiteConfiguration?)
    func start(completion: @escaping NinchatSessionCompletion) throws
    func start(credentials: NINSessionCredentials, completion: @escaping NinchatSessionCompletion) throws
    func chatSession(within navigationController: UINavigationController?) throws -> UIViewController?
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
    private lazy var coordinator: Coordinator = {
        NINCoordinator(with: self)
    }()
    private let audienceMetadata: NINLowLevelClientProps?
    private let configuration: NINSiteConfiguration?
    private var configKey: String!
    private var queueID: String?
    private var environments: [String]?
    private var started: Bool! = false
    private var resumed: Bool! = false
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
    public var session: NINResult<NINLowLevelClientSession?> {
        guard self.started else { return .failure(NINExceptions.apiNotStarted) }
        return .success(self.sessionManager.session)
    }
    public var appDetails: String? {
        set { sessionManager.appDetails = newValue }
        get { sessionManager.appDetails }
    }

    public init(configKey: String, queueID: String? = nil, environments: [String]? = nil, metadata: NINLowLevelClientProps? = nil, configuration: NINSiteConfiguration? = nil) {
        self.configKey = configKey
        self.queueID = queueID
        self.environments = environments
        self.audienceMetadata = metadata
        self.configuration = configuration
        self.serverAddress = Constants.kProductionServerAddress.rawValue
        self.started = false
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
                        try self?.openChatSession(completion: completion)
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
                        try self?.openChatSession(credentials: credentials, completion: completion)
                    } catch { completion(nil, error) }
                }
            }
        } catch { completion(nil, error) }
    }

    public func chatSession(within navigationController: UINavigationController?) throws -> UIViewController? {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        guard self.started else { throw NINExceptions.apiNotStarted }
        
        return coordinator.start(with: self.queueID ?? self.sessionManager.siteConfiguration.audienceAutoQueue, resumeSession: self.resumed, within: navigationController)
    }

    public func deallocate() {
        self.coordinator.deallocate()
        self.sessionManager?.deallocateSession()
        self.sessionManager = nil
        self.started = false
    }
}

// MARK: - Private helper methods

/// Shared helper
extension NINChatSession {
    private func fetchSiteConfiguration(completion: @escaping (Error?) -> Void) throws {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        sessionManager.fetchSiteConfiguration(config: configKey, environments: environments) { error in
            completion(error)
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
                try self?.listAllQueues(credentials: credentials, completion: completion)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func listAllQueues(credentials: NINSessionCredentials?, completion: @escaping NinchatSessionCompletion) throws {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        var allQueues = sessionManager.siteConfiguration.audienceQueues ?? []
        if let queue = queueID { allQueues.append(queue) }
        
        try sessionManager.list(queues: allQueues) { [weak self] error in
            self?.started = (error == nil)
            self?.resumed = false
            completion(credentials, error)
        }
    }
}

/// Resuming Session helpers
extension NINChatSession {
    private func openChatSession(credentials: NINSessionCredentials, completion: @escaping NinchatSessionCompletion) throws {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        try sessionManager.continueSession(credentials: credentials) { [weak self] newCredential, canResume, error in
            if newCredential?.sessionID != credentials.sessionID {
                self?.sessionManager.closeSession(credentials: credentials, completion: nil)
            }

            if (error != nil || !canResume) && (self?.internalDelegate?.onResumeFailed() ?? false) {
                try? self?.openChatSession(completion: completion); return
            }

            self?.started = true
            self?.resumed = canResume
            /// Keep userID and userAuth and just update sessionID
            completion(NINSessionCredentials(userID: credentials.userID, userAuth: credentials.userAuth, sessionID: newCredential?.sessionID), error)
        }
    }
}
