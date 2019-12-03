//
//  NINChatSession.swift
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 22.11.2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

import UIKit
import NinchatSDK
import NinchatLowLevelClient

public typealias EmptyClouser = (Error?) -> Void

public protocol NINChatSessionProtocol {
    /// delegate will be deprecated soon. Use clousers instead
    var delegate: NINChatSessionDelegate? { get set }
    
    var serverAddress: String { get set }
    var siteSecret: String? { get set }
    var audienceMetadata: NINLowLevelClientProps? { get set }
    var session: NINLowLevelClientSession { get }
    
    init(configKey: String, queueID: String?, environments: [String]?)
    func start(completion: @escaping EmptyClouser)
    func viewController(withNavigationController navigation: Bool) throws -> UIViewController?
}
public extension NINChatSessionProtocol {
    init(configKey: String, queueID: String?) {
        self.init(configKey: configKey, queueID: queueID, environments: nil)
    }
}

public final class NINChatSession: NINChatSessionProtocol {
    private let sessionManager = NINSessionManager()
    private let configKey: String
    private let queueID: String?
    private let environments: [String]?
    private var started: Bool!
    
    // MARK: - NINChatSessionProtocol
    
    public weak var delegate: NINChatSessionDelegate?
    
    public init(configKey: String, queueID: String?, environments: [String]?) {
        self.configKey = configKey
        self.queueID = queueID
        self.environments = environments
        
        self.started = false
    }
    
    public var serverAddress: String {
        set {
            self.sessionManager.serverAddress = newValue
        }
        get {
            return self.sessionManager.serverAddress ?? defaultServerAddress
        }
    }
    
    public var siteSecret: String? {
        set {
            self.sessionManager.siteSecret = newValue
        }
        get {
            return self.sessionManager.siteSecret
        }
    }
    
    public var audienceMetadata: NINLowLevelClientProps? {
        set {
            self.sessionManager.audienceMetadata = newValue
        }
        get {
            return self.sessionManager.audienceMetadata
        }
    }
    
    public var session: NINLowLevelClientSession {
        guard self.started else {
            fatalError("API has not been started")
        }
        return self.sessionManager.session
    }
    
    /// Performs these steps:
    /// 1. Fetches the site configuration over a REST call
    /// 2. Using that configuration, starts a new chat session
    /// 3. Retrieves the queues available for this realm (realm id from site configuration)
    public func start(completion: @escaping EmptyClouser) {
        // Fetch the site configuration
        self.fetchSiteConfiguration(completion: completion)
    }
    
    public func viewController(withNavigationController navigation: Bool) throws -> UIViewController? {
        guard Thread.isMainThread else {
            fatalError("Must be called in main thread")
        }
        guard self.started else {
            throw NINChatExceptions.apiNotStarted
        }
        
        if let queueID = self.queueID {
            return joinAutomatically(to: queueID)
        }
        return showJoinOptions(with: navigation)
    }
}

// MARK: - Private helper methods

private extension NINChatSession {
    private var defaultServerAddress: String {
        #if NIN_USE_TEST_SERVER
        return Constants.kTestServerAddress.rawValue
        #else
        return Constants.kProductionServerAddress.rawValue
        #endif
    }
    
    private func fetchSiteConfiguration(completion: @escaping EmptyClouser) {
        fetchSiteConfig(serverAddress, configKey) { [weak self] config, error in
            if let error = error {
                completion(error)
                return
            }
            
            #if DEBUG
            print("Got site config: \(String(describing: config))")
            #endif
            
            self?.sessionManager.siteConfiguration = NINSiteConfiguration(config)
            self?.sessionManager.siteConfiguration.environments = self?.environments
            
            // Open the chat session
            self?.openChatSession(completion: completion)
        }
    }
    
    @discardableResult
    private func openChatSession(completion: @escaping EmptyClouser) -> Error {
        return sessionManager.openSession({ [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            
            /// Find our realm's queues
            /// Potentially passing a nil queueIds here is intended
            self?.listAllQueues(completion: completion)
        })
    }
    
    private func listAllQueues(completion: @escaping EmptyClouser) {
        var allQueues = sessionManager.siteConfiguration.value(forKey: "audienceQueues") as? [String] ?? []
        if let queue = queueID {
            allQueues.append(queue)
        }
        
        sessionManager.listQueues(withIds: allQueues) { [weak self] error in
            self?.started = error == nil
            completion(error)
        }
    }
}

private extension NINChatSession {
    private func joinAutomatically(to queue: String) -> UIViewController? {
        guard let queueID = self.queueID, let queue = self.sessionManager.queues.compactMap({ $0 }).filter({ $0.queueID ==
            queueID }).first else {
                return nil
        }
        
        guard let vc = UIStoryboard(name: "Chat", bundle: findResourceBundle()).instantiateViewController(withIdentifier: "NINQueueViewController") as? NINQueueViewController else {
            fatalError("Invalid NINQueueViewController")
        }
        vc.sessionManager = self.sessionManager
        vc.queueToJoin = queue
        
        return vc
    }
    
    private func showJoinOptions(with withNavigation: Bool) -> UIViewController? {
        guard let navigationController = UIStoryboard(name: "Chat", bundle: findResourceBundle()).instantiateInitialViewController() as? UINavigationController else {
            fatalError("Storyboard initial view controller is not UINavigationController")
        }
        if withNavigation {
            return navigationController
        }
        
        guard let initialViewController = navigationController.topViewController as? NINInitialViewController else {
            fatalError("Storyboard navigation controller's top view controller is not NINInitialViewController")
        }
        initialViewController.sessionManager = self.sessionManager
        return initialViewController
    }
}

// MARK: - Internal helper methods

extension NINChatSession {
    func log(format: String, _ args: CVarArg...) {
        self.delegate?.didOutputSDKLog(session: self, log: String(format: format, args))
    }
    
    func override(imageAsset key: NINImageAssetKey) -> UIImage? {
        guard let assetKey = AssetConstants(rawValue: key) else {
            fatalError("Cannot convert `NINImageAssetKey` to `AssetConstants`")
        }
        return self.delegate?.overrideImageAsset(session: self, forKey: assetKey)
    }
    
    func override(colorAsset key: NINColorAssetKey) -> UIColor? {
        guard let colorKey = ColorConstants(rawValue: key) else {
            fatalError("Cannot convert `NINColorAssetKey` to `ColorConstants`")
        }
        return self.delegate?.overrideColorAsset(session: self, forKey: colorKey)
    }
}
