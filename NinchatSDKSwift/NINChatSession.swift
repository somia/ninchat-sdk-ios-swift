//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

public protocol NINChatDevHelper {
    var serverAddress: String! { get set }
    var siteSecret: String? { get set }
}

public protocol NINChatSessionProtocol: NINChatSessionClosure {
    /**
    * Append information to the user agent string. The string should be in
    * the form "app-name/version" or "app-name/version (more; details)".
    *
    * Set this prior to calling startWithCallback:
    */
    var appDetails: String? { get set }
    var delegate: NINChatSessionDelegateSwift? { get set }
    
    init(configKey: String, queueID: String?, environments: [String]?, metadata: NINLowLevelClientProps?)
    func start(completion: @escaping (Error?) -> Void)
    func chatSession(within navigationController: UINavigationController) throws -> UIViewController?
    func clientSession() throws -> NINLowLevelClientSession?
}

public final class NINChatSessionSwift: NINChatSessionProtocol, NINChatDevHelper {
    var sessionManager: NINChatSessionManager!
    private var coordinator: Coordinator!
    private var configKey: String!
    private var queueID: String?
    private var environments: [String]?
    private var started: Bool!
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
    
    // MARK: - NINChatSessionClosure
    
    public var didOutputSDKLog: ((NINChatSessionSwift, String) -> Void)?
    public var onLowLevelEvent: ((NINChatSessionSwift, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)?
    public var overrideImageAsset: ((NINChatSessionSwift, AssetConstants) -> UIImage?)?
    public var overrideColorAsset: ((NINChatSessionSwift, ColorConstants) -> UIColor?)?
    public var didEndSession: ((NINChatSessionSwift) -> Void)?
    
    // MARK: - NINChatSessionProtocol
    
    public weak var delegate: NINChatSessionDelegateSwift?
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
    
    
    public func clientSession() throws -> NINLowLevelClientSession? {
        guard self.started else { throw NINExceptions.apiNotStarted }
        return self.sessionManager.session
    }
    
    /// Performs these steps:
    /// 1. Fetches the site configuration over a REST call
    /// 2. Using that configuration, starts a new chat session
    /// 3. Retrieves the queues available for this realm (realm id from site configuration)
    public func start(completion: @escaping (Error?) -> Void) {
        /// Fetch the site configuration
        self.fetchSiteConfiguration(completion: completion)
    }
    
    public func chatSession(within navigationController: UINavigationController) throws -> UIViewController? {
        guard Thread.isMainThread else { throw NINExceptions.mainThread }
        guard self.started else { throw NINExceptions.apiNotStarted }
        
        return coordinator.start(with: self.queueID, within: navigationController)
    }
}

// MARK: - Private helper methods

private extension NINChatSessionSwift {
    private func fetchSiteConfiguration(completion: @escaping (Error?) -> Void) {
        sessionManager.fetchSiteConfiguration(config: configKey, environments: environments) { [weak self] error in
            if let error = error {
                completion(error); return
            }
            
            do {
                // Open the chat session
                try self?.openChatSession(completion: completion)
            } catch {
                completion(error)
            }
        }
    }
    
    private func openChatSession(completion: @escaping (Error?) -> Void) throws {
        try sessionManager.openSession { [weak self] error in
            if let error = error {
                completion(error); return
            }
            
            do {
                /// Find our realm's queues
                /// Potentially passing a nil queueIds here is intended
                try self?.listAllQueues(completion: completion)
            } catch {
                completion(error)
            }
        }
    }
    
    private func listAllQueues(completion: @escaping (Error?) -> Void) throws {
        var allQueues = sessionManager.siteConfiguration.audienceQueues ?? []
        if let queue = queueID {
            allQueues.append(queue)
        }
        
        try sessionManager.list(queues: allQueues) { [weak self] error in
            self?.started = (error == nil)
            completion(error)
        }
    }
}
