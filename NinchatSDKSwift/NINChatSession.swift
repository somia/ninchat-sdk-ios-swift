//
//  NINChatSession.swift
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 22.11.2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

import UIKit
import NinchatSDK

public protocol NINChatSessionProtocol: NINChatSessionClosure {
    var delegateSwift: NINChatSessionDelegateSwift? { get set }
    
    var serverAddress: String? { get set }
    var siteSecret: String? { get set }
    var audienceMetadata: NINLowLevelClientProps? { get set }
    var session: NINLowLevelClientSession { get }
    
    init(configKey: String, queueID: String?, environments: [String]?)
    func start(completion: @escaping (Error?) -> Void)
    func chatSession(within navigationController: UINavigationController) throws -> UIViewController?
}
public extension NINChatSessionProtocol {
    init(configKey: String) {
        self.init(configKey: configKey, queueID: nil, environments: nil)
    }
    init(configKey: String, queueID: String?) {
        self.init(configKey: configKey, queueID: queueID, environments: nil)
    }
}

public final class NINChatSessionSwift: NINChatSession, NINChatSessionProtocol {
    let sessionManager = NINSessionManager()
    private let coordinator: Coordinator! = NINCoordinator()
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
    
    // MARK: - NINChatSessionClosure
    
    public var didOutputSDKLog: ((NINChatSession, String) -> Void)?
    public var onLowLevelEvent: ((NINChatSession, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)?
    public var overrideImageAsset: ((NINChatSession, AssetConstants) -> UIImage?)?
    public var overrideColorAsset: ((NINChatSession, ColorConstants) -> UIColor?)?
    public var didEndSession: ((NINChatSession) -> Void)?
    
    // MARK: - NINChatSessionProtocol
    
    public weak var delegateSwift: NINChatSessionDelegateSwift?
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
    
    public func chatSession(within navigationController: UINavigationController) throws -> UIViewController? {
        guard Thread.isMainThread else {
            throw NINChatExceptions.mainThread
        }
        guard self.started else {
            throw NINChatExceptions.apiNotStarted
        }
        return coordinator.start(with: self.queueID, in: self, within: navigationController)
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

// MARK: - Internal helper methods

extension NINChatSessionSwift {
    func log(format: String, _ args: CVarArg...) {
        self.ninchat(self, didOutputSDKLog: String(format: format, args))
    }
    
    func override(imageAsset key: AssetConstants) -> UIImage? {
        return self.ninchat(self, overrideImageAssetForKey: key.rawValue)
    }
    
    func override(colorAsset key: ColorConstants) -> UIColor? {
        return self.ninchat(self, overrideColorAssetForKey: key.rawValue)
    }
}
