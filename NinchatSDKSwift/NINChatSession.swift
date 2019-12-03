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

public protocol NINChatSessionProtocol {
    var delegateSwift: NINChatSessionDelegateSwift? { get set }
    var didOutputSDKLog: ((NINChatSession, String) -> Void)? { get set }
    var onLowLevelEvent: ((NINChatSession, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)? { get set }
    var overrideImageAsset: ((NINChatSession, AssetConstants) -> UIImage?)? { get set }
    var overrideColorAsset: ((NINChatSession, ColorConstants) -> UIColor?)? { get set }
    var didEndSession: ((NINChatSession) -> Void)? { get set }
    
    var serverAddress: String? { get set }
    var siteSecret: String? { get set }
    var audienceMetadata: NINLowLevelClientProps? { get set }
    var session: NINLowLevelClientSession { get }
    
    init(configKey: String, queueID: String?, environments: [String]?)
    init(configKey: String, queueID: String?)
    func start(completion: @escaping (Error?) -> Void)
    func viewController(withNavigationController navigation: Bool) throws -> UIViewController?
}

public final class NINChatSessionSwift: NINChatSession, NINChatSessionProtocol {
    private let sessionManager = NINSessionManager()
    private let configKey: String
    private let queueID: String?
    private let environments: [String]?
    private var started: Bool!
    private var defaultServerAddress: String {
        #if NIN_USE_TEST_SERVER
        return Constants.kTestServerAddress.rawValue
        #else
        return Constants.kProductionServerAddress.rawValue
        #endif
    }
    
    // MARK: - NINChatSessionProtocol
    
    public weak var delegateSwift: NINChatSessionDelegateSwift?
    public var didOutputSDKLog: ((NINChatSession, String) -> Void)?
    public var onLowLevelEvent: ((NINChatSession, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)?
    public var overrideImageAsset: ((NINChatSession, AssetConstants) -> UIImage?)?
    public var overrideColorAsset: ((NINChatSession, ColorConstants) -> UIColor?)?
    public var didEndSession: ((NINChatSession) -> Void)?
    
    override public var serverAddress: String? {
        set {
            self.sessionManager.serverAddress = newValue
        }
        get {
            return self.sessionManager.serverAddress ?? defaultServerAddress
        }
    }
    override public var siteSecret: String? {
        set {
            self.sessionManager.siteSecret = newValue
        }
        get {
            return self.sessionManager.siteSecret
        }
    }
    override public var audienceMetadata: NINLowLevelClientProps? {
        set {
            self.sessionManager.audienceMetadata = newValue
        }
        get {
            return self.sessionManager.audienceMetadata
        }
    }
    override public var session: NINLowLevelClientSession {
        guard self.started else {
            fatalError("API has not been started")
        }
        return self.sessionManager.session
    }
    
    public convenience init(configKey: String) {
        self.init(configKey: configKey, queueID: nil, environments: nil)
    }
    public convenience init(configKey: String, queueID: String?) {
        self.init(configKey: configKey, queueID: queueID, environments: nil)
    }
    public init(configKey: String, queueID: String?, environments: [String]?) {
        self.configKey = configKey
        self.queueID = queueID
        self.environments = environments
        
        super.init()
        self.started = false
        self.delegate = self
        self.sessionManager.ninchatSession = self
    }
    
    /// Performs these steps:
    /// 1. Fetches the site configuration over a REST call
    /// 2. Using that configuration, starts a new chat session
    /// 3. Retrieves the queues available for this realm (realm id from site configuration)
    public func start(completion: @escaping (Error?) -> Void) {
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

extension NINChatSessionSwift: NINChatSessionDelegate {
    public func ninchat(_ session: NINChatSession, didOutputSDKLog value: String) {
        guard let ninchatSwift = session as? NINChatSessionSwift else {
            fatalError("Cannot convert `NINChatSession` to `NINChatSessionSwift`")
        }
        self.delegateSwift?.didOutputSDKLog(session: ninchatSwift, value: value)
        self.didOutputSDKLog?(ninchatSwift, value)
    }
    
    public func ninchat(_ session: NINChatSession, onLowLevelEvent event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
        guard let ninchatSwift = session as? NINChatSessionSwift else {
            fatalError("Cannot convert `NINChatSession` to `NINChatSessionSwift`")
        }
        self.delegateSwift?.onLowLevelEvent(session: ninchatSwift, params: event, payload: payload, lastReply: lastReply)
        self.onLowLevelEvent?(ninchatSwift, event, payload, lastReply)
    }
    
    public func ninchat(_ session: NINChatSession, overrideImageAssetForKey assetKey: NINImageAssetKey) -> UIImage? {
        guard let assetKey = AssetConstants(rawValue: assetKey), let ninchatSwift = session as? NINChatSessionSwift else {
            fatalError("Cannot convert `NINImageAssetKey` to `AssetConstants` or `NINChatSession` to `NINChatSessionSwift`")
        }
        if let delegate = self.delegateSwift {
            return delegate.overrideImageAsset(session: ninchatSwift, forKey: assetKey)
        }
        return self.overrideImageAsset?(ninchatSwift, assetKey)
    }
    
    public func ninchat(_ session: NINChatSession, overrideColorAssetForKey colorKey: NINColorAssetKey) -> UIColor? {
        guard let colorKey = ColorConstants(rawValue: colorKey), let ninchatSwift = session as? NINChatSessionSwift else {
            fatalError("Cannot convert `NINColorAssetKey` to `ColorConstants` or `NINChatSession` to `NINChatSessionSwift`")
        }
        if let delegate = self.delegateSwift {
            return delegate.overrideColorAsset(session: ninchatSwift, forKey: colorKey)
        }
        return self.overrideColorAsset?(ninchatSwift, colorKey)
    }
    
    public func ninchatDidEnd(_ ninchat: NINChatSession) {
        guard let ninchatSwift = ninchat as? NINChatSessionSwift else {
            fatalError("Cannot convert `NINChatSession` to `NINChatSessionSwift`")
        }
        self.delegateSwift?.didEndSession(session: ninchatSwift)
        self.didEndSession?(ninchatSwift)
    }
}

// MARK: - Private helper methods

private extension NINChatSessionSwift {
    private func fetchSiteConfiguration(completion: @escaping (Error?) -> Void) {
        fetchSiteConfig(serverAddress!, configKey) { [weak self] config, error in
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
    private func openChatSession(completion: @escaping (Error?) -> Void) -> Error {
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
    
    private func listAllQueues(completion: @escaping (Error?) -> Void) {
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

private extension NINChatSessionSwift {
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

extension NINChatSessionSwift {
    func log(format: String, _ args: CVarArg...) {
        self.ninchat(self, didOutputSDKLog: String(format: format, args))
    }
    
    func override(imageAsset key: NINImageAssetKey) -> UIImage? {
        return self.ninchat(self, overrideImageAssetForKey: key)
    }
    
    func override(colorAsset key: NINColorAssetKey) -> UIColor? {
        return self.ninchat(self, overrideColorAssetForKey: key)
    }
}
