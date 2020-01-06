//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

public protocol NINChatSessionProtocol: NINChatSessionClosure {
    var delegate: NINChatSessionDelegateSwift? { get set }
    
    init(configKey: String, queueID: String?, environments: [String]?, serverAddress: String?, siteSecret: String?, metadata: NINLowLevelClientProps?)
    func start(completion: @escaping (Error?) -> Void)
    func chatSession(within navigationController: UINavigationController) throws -> UIViewController?
    func clientSession() throws -> NINLowLevelClientSession?
}

public final class NINChatSessionSwift: NINChatSessionProtocol {
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
    
    // MARK: - NINChatSessionClosure
    
    public var didOutputSDKLog: ((NINChatSessionSwift, String) -> Void)?
    public var onLowLevelEvent: ((NINChatSessionSwift, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)?
    public var overrideImageAsset: ((NINChatSessionSwift, AssetConstants) -> UIImage?)?
    public var overrideColorAsset: ((NINChatSessionSwift, ColorConstants) -> UIColor?)?
    public var didEndSession: ((NINChatSessionSwift) -> Void)?
    
    // MARK: - NINChatSessionProtocol
    
    public weak var delegate: NINChatSessionDelegateSwift?
    
    public init(configKey: String, queueID: String? = nil, environments: [String]? = nil, serverAddress: String? = nil, siteSecret: String? = nil, metadata: NINLowLevelClientProps? = nil) {
        self.configKey = configKey
        self.queueID = queueID
        self.environments = environments
        self.started = false
        
        self.coordinator = NINCoordinator(with: self)
        self.sessionManager = NINChatSessionManagerImpl(session: self, serverAddress: serverAddress ?? defaultServerAddress, siteSecret: siteSecret, audienceMetadata: metadata)
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
