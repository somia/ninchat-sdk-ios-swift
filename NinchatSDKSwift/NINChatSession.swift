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

    init(configKey: String, queueID: String?, environments: [String]?, metadata: NINLowLevelClientProps?)
    func start(completion: @escaping NinchatSessionCompletion) throws
    func start(credentials: NINSessionCredentials, completion: @escaping NinchatSessionCompletion) throws
    func chatSession(within navigationController: UINavigationController?) throws -> UIViewController?
}

public final class NINChatSession: NINChatSessionProtocol, NINChatDevHelper {
    var sessionManager: NINChatSessionManager!
    private var coordinator: Coordinator!
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
    
    public var serverAddress: String! = Constants.kProductionServerAddress.rawValue {
        didSet {
            self.sessionManager.serverAddress = serverAddress
        }
    }
    public var siteSecret: String? = nil {
        didSet {
            self.sessionManager.siteSecret = siteSecret
        }
    }

    // MARK: - NINChatSessionProtocol
    
    public weak var delegate: NINChatSessionDelegate?
    public var session: NINResult<NINLowLevelClientSession?> {
        guard self.started else { return .failure(NINExceptions.apiNotStarted) }
        return .success(self.sessionManager.session)
    }
    public var appDetails: String? {
        didSet {
            sessionManager.appDetails = appDetails
        }
    }

    public init(configKey: String, queueID: String? = nil, environments: [String]? = nil, metadata: NINLowLevelClientProps? = nil) {
        self.configKey = configKey
        self.queueID = queueID
        self.environments = environments
        self.started = false
    
        self.coordinator = NINCoordinator(with: self)
        self.sessionManager = NINChatSessionManagerImpl(session: self, serverAddress: defaultServerAddress, audienceMetadata: metadata)
    }

    /// Performs these steps:
    /// 1. Fetches the site configuration over a REST call
    /// 2. Using that configuration, starts a new chat session
    /// 3. Retrieves the queues available for this realm (realm id from site configuration)
    public func start(completion: @escaping NinchatSessionCompletion) throws {
        debugger("Starting a new chat session")
        self.fetchSiteConfiguration { error in
            do {
                try self.openChatSession(completion: completion)
            } catch { completion(nil, error) }
        }
    }

    /**
     * Starts the API engine using given credentials. Must be called before other API methods.
     * If callback returns the error indicating invalidated credentials, the caller is responsible to decide
     * for using `start(completion:)` and starting a new chat session.
    */
    public func start(credentials: NINSessionCredentials, completion: @escaping NinchatSessionCompletion) throws {
        debugger("Trying to continue given chat session")
        self.fetchSiteConfiguration { error in
            do {
                try self.openChatSession(credentials: credentials, completion: completion)
            } catch { completion(nil, error) }
        }
    }

    public func chatSession(within navigationController: UINavigationController?) throws -> UIViewController? {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        guard self.started else { throw NINExceptions.apiNotStarted }
        
        return coordinator.start(with: self.queueID, resumeSession: self.resumed, within: navigationController)
    }
}

// MARK: - Private helper methods

/// Shared helper
extension NINChatSession {
    private func fetchSiteConfiguration(completion: @escaping (Error?) -> Void) {
        sessionManager.fetchSiteConfiguration(config: configKey, environments: environments) { error in
            completion(error)
        }
    }
}

/// Fresh Session helpers
extension NINChatSession {
    private func openChatSession(completion: @escaping NinchatSessionCompletion) throws {
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
        try sessionManager.continueSession(credentials: credentials) { [weak self] newCredential, canResume, error in
            if newCredential?.sessionID != credentials.sessionID {
                self?.sessionManager.closeSession(credentials: credentials, completion: nil)
            }

            if (error != nil || !canResume) && (self?.onResumeFailed() ?? false) {
                try? self?.openChatSession(completion: completion); return
            }

            self?.started = true
            self?.resumed = canResume
            /// Keep userID and userAuth and just update sessionID
            completion(NINSessionCredentials(userID: credentials.userID, userAuth: credentials.userAuth, sessionID: newCredential?.sessionID), error)
        }
    }
}
