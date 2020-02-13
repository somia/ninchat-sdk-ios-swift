//
// Copyright (c) 26.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

protocol NINChatSessionManagerInternalActions {
    var onActionSessionEvent: ((Events, Error?) -> Void)? { get set }
    var onActionID: ((_ actionID: Int, Error?) -> Void)? { get set }
    var onProgress: ((_ queueID: String, _ position: Int, Events, Error?) -> Void)? { get set }
    var onChannelJoined: Completion? { get set }
    var onActionSevers: ((_ actionID: Int, _ stunServers: [NINWebRTCServerInfo]?, _ turnServers: [NINWebRTCServerInfo]?) -> Void)? { get set }
    var onActionFileInfo: ((_ actionID: Int, _ fileInfo: [String:Any]?, Error?) -> Void)? { get set }
    var onActionChannel: ((_ actionID: Int, _ channelID: String) -> Void)? { get set }
}

final class NINChatSessionManagerImpl: NINChatSessionManager, NINChatSessionManagerInternalActions {
    internal let serverAddress: String
    internal let siteSecret: String?
    internal let audienceMetadata: NINLowLevelClientProps?
    
    internal var channelUsers: [String:NINChannelUser] = [:]
    internal var currentQueueID: String?
    internal var currentChannelID: String?
    internal var backgroundChannelID: String?
    internal var myUserID: String?
    internal var realmID: String?
    internal var messageThrottler: NINMessageThrottler?
    
    // MARK: - NINChatSessionManagerInternalActions
    
    internal var onActionSessionEvent: ((Events, Error?) -> Void)?
    internal var onActionID: ((Int, Error?) -> Void)?
    internal var onProgress: ((String, Int, Events, Error?) -> Void)?
    internal var onChannelJoined: Completion?
    internal var onActionSevers: ((Int, [NINWebRTCServerInfo]?, [NINWebRTCServerInfo]?) -> Void)?
    internal var onActionFileInfo: ((Int, [String:Any]?, Error?) -> Void)?
    internal var onActionChannel: ((Int, String) -> Void)?

    // MARK: - NINChatSessionManagerClosureHandler

    internal var actionBoundClosures: [Int:((Error?) -> Void)] = [:]
    internal var queueUpdateBoundClosures: [String:((Events, String, Error?) -> Void)] = [:]

    // MARK: - NINChatSessionConnectionManager variables
    
    var session: NINLowLevelClientSession?
    var connected: Bool! {
        return self.session != nil
    }
    
    // MARK: - NINChatSessionManager variables
    
    var chatMessages: [NINChatMessage]! = []
    
    // MARK: - NINChatSessionManagerDelegate

    var onMessageAdded: ((_ index: Int) -> Void)?
    var onMessageRemoved: ((_ index: Int) -> Void)?
    var onChannelClosed: (() -> Void)?
    var onRTCSignal: ((MessageType, NINChannelUser?, _ signal: RTCSignal?) -> Void)?
    var onRTCClientSignal: ((MessageType, NINChannelUser?, _ signal: RTCSignal?) -> Void)?

    func bindQueueUpdate<T: QueueUpdateCapture>(closure: @escaping ((Events, String, Error?) -> Void), to receiver: T) {
        guard queueUpdateBoundClosures.keys.filter({ $0 == receiver.desc }).count == 0 else { return }
        queueUpdateBoundClosures[receiver.desc] = closure
    }

    func unbindQueueUpdateClosure<T: QueueUpdateCapture>(from receiver: T) {
        self.queueUpdateBoundClosures.removeValue(forKey: receiver.desc)
    }

    // MARK: - NINChatSessionManager
    
    weak var delegate: NINChatSessionInternalDelegate?
    var queues: [NINQueue]! = [] {
        didSet {
            self.audienceQueues = self.queues
        }
    }
    var audienceQueues: [NINQueue]! = []
    var siteConfiguration: NINSiteConfiguration!
    var appDetails: String?
    
    init(session: NINChatSessionInternalDelegate, serverAddress: String, siteSecret: String? = nil, audienceMetadata: NINLowLevelClientProps? = nil) {
        self.delegate = session
        self.serverAddress = serverAddress
        self.siteSecret = siteSecret
        self.audienceMetadata = audienceMetadata
    }
    
    deinit {
        self.disconnect()
        debugger("`NINChatSessionManager` deallocated.")
    }
}

// MARK: - NINChatSessionConnectionManager

extension NINChatSessionManagerImpl {
    private var sdkDetails: String {
        var details = "ninchat-sdk-ios"
        
        /// SDK Version
        if let sdkVersion = Bundle.SDKBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
            details += "/\(sdkVersion)"
        }
        
        /// Device OS
        details += " (ios " + UIDevice.current.systemVersion + "; "
        
        /// Device Model
        details += UIDevice.current.deviceType + ")"
        
        /// User given details
        if let appDetails = self.appDetails {
            details += " " + appDetails
        }
        
        return details
    }
    
    func fetchSiteConfiguration(config key: String, environments: [String]?, completion: @escaping CompletionWithError) {
        fetchSiteConfig(self.serverAddress, key) { (config, error) in
            if let error = error {
                completion(error); return
            }
            
            debugger("Got site config: \(String(describing: config))")
            self.siteConfiguration = NINSiteConfiguration(config)
            self.siteConfiguration.environments = environments
            completion(nil)
        }
    }
    
    func openSession(completion: @escaping CompletionWithError) throws {
        guard self.session == nil else { throw NINSessionExceptions.hasActiveSession }
        delegate?.log(value: "Opening new chat session using server address: \(serverAddress)")
        
        /// Wait for the session creation event
        self.onActionSessionEvent = { event, error in
            if event == .sessionCreated { completion(error) }
        }
        
        /// Create message throttler to manage inbound message order
        self.messageThrottler = NINMessageThrottler { [weak self] message in
             try? self?.didReceiveMessage(param: message.params, payload: message.payload)
        }
        
        /// Make sure our site configuration contains a realm_id
        guard let realmId = self.siteConfiguration.audienceRealm else { throw NINSessionExceptions.invalidRealmConfiguration }
        self.realmID = realmId
        
        let sessionParam = NINLowLevelClientProps.initiate
        if let secret = self.siteSecret {
            sessionParam.set(site: secret)
        }
        
        if let userName = self.siteConfiguration.username {
            let attr = NINLowLevelClientProps.initiate
            attr.set(name: userName)
            sessionParam.set(user: attr)
        }
        
        let messageType = NINLowLevelClientStrings.initiate
        messageType.append("ninchat.com/*")
        sessionParam.set(message: messageType)
        
        self.session = NINLowLevelClientSession()
        self.session?.setAddress(self.serverAddress)
        self.session?.setHeader("User-Agent", value: self.sdkDetails)
        self.setEventHandlers()
        
        try self.session?.setParams(sessionParam)
        try self.session?.open()
    }
    
    func list(queues ID: [String]?, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }

        let param = NINLowLevelClientProps.initiate
        param.set_realmQueues()
        param.set(releamID: realmID!)
        if let queues = ID {
            param.set(queues: queues.reduce(into: NINLowLevelClientStrings.initiate) { list, id in
                list.append(id)
            })
        }
        
        do {
            let actionID = try session.send(param)
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
    
    func join(queue ID: String, progress: @escaping ((Error?, Int) -> Void), completion: @escaping Completion) throws {
        
        func performJoin() throws {
            delegate?.log(value: "Joining queue \(ID)..")
            self.onChannelJoined = {
                completion()
            }
            
            /// Check if we are already in an active queue
            if self.currentQueueID == nil {
                guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
                
                let param = NINLowLevelClientProps.initiate
                param.set_requestAudeience()
                param.set(queue: ID)
                if let audienceMetadata = self.audienceMetadata {
                    param.set(metadata: audienceMetadata)
                }
                do {
                    _ = try session.send(param)
                } catch {
                    progress(error, -1)
                }
            }

            self.onProgress = { [weak self] queueID, position, event, error in
                if (event == .queueUpdated || event == .audienceEnqueued), self?.currentQueueID == queueID {
                    progress(error, position)
                }
            }
        }
        
        if let currentChannel = self.currentChannelID {
            delegate?.log(value: "Parting current channel first")
            
            try self.part(channel: currentChannel) { [unowned self] error in
                self.delegate?.log(value: "Channel parted; joining queue.")
                self.backgroundChannelID = self.currentChannelID
                self.currentChannelID = nil
                try? performJoin()
            }
        } else {
            try performJoin()
        }
    }
    
    /// Leaves the current queue, if any
    func leave(completion: @escaping CompletionWithError) {
        guard self.currentQueueID != nil else {
            delegate?.log(value: "Error: tried to leave current queue but not in queue currently!")
            return
        }
        
        delegate?.log(value: "Leaving current queue.")
        self.onChannelJoined = nil
        self.onProgress = nil
        completion(nil)
    }
    
    /// Retrieves the WebRTC ICE STUN/TURN server details
    func beginICE(completion: @escaping ((Error?, [NINWebRTCServerInfo]?, [NINWebRTCServerInfo]?) -> Void)) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        let param = NINLowLevelClientProps.initiate
        param.set_beginICE()
        
        do {
            let actionID = try session.send(param)
            self.onActionSevers = { id, stunServers, turnServers in
                guard id == actionID else { return }
                
                completion(nil, stunServers, turnServers)
            }
        } catch {
            completion(error, nil, nil)
        }
    }
    
    /// Low-level shutdown of the chatsession; invalidates session resource.
    func closeChat() throws {
        delegate?.log(value: "Shutting down chat Session..")
        try self.deleteCurrentUser { [unowned self] error in
            self.disconnect()
            
            /// Signal the delegate that our session has ended
            self.delegate?.onDidEnd()
        }
    }
    
    /// High-level chat ending; sends channel metadata and then closes session.
    func finishChat(rating status: ChatStatus?) throws {
        guard self.session != nil else { throw NINSessionExceptions.noActiveSession }
        
        if let rating = status {
            try self.send(type: .metadata, payload: ["data": ["rating": rating.rawValue]]) { [weak self] _ in
                try? self?.closeChat()
            }
        } else {
            try self.closeChat()
        }
    }
}

// MARK: - NINChatSessionMessenger

extension NINChatSessionManagerImpl {
    func update(isWriting: Bool, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        guard let currentChannel = self.currentChannelID else { throw NINSessionExceptions.noActiveQueue }
        guard let userID = self.myUserID else { throw NINSessionExceptions.noActiveUserID }
        
        let memberAttributes = NINLowLevelClientProps.initiate
        memberAttributes.set(isWriting: isWriting)
        
        let param = NINLowLevelClientProps.initiate
        param.set_updateMember()
        param.set(channel: currentChannel)
        param.set(user: userID)
        param.set(member: memberAttributes)
        
        do {
            let actionID = try session.send(param)
            
            /// When this action completes, trigger the completion block callback
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
    
    /// Sends a text message to the current channel
    func send(message: String, completion: @escaping CompletionWithError) throws {
        guard self.session != nil else { throw NINSessionExceptions.noActiveSession }
        
        try self.send(type: .text, payload: ["text": message], completion: completion)
    }
    
    /// Sends a ui/action response to the current channel
    func send(action: NINComposeContentView, completion: @escaping CompletionWithError) throws {
        guard self.session != nil else { throw NINSessionExceptions.noActiveSession }
        
        try self.send(type: .uiAction, payload: ["action": "click", "target": action.composeMessageDict], completion: completion)
    }
    
    func send(attachment: String, data: Data, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        guard let currentChannel = self.currentChannelID else { throw NINSessionExceptions.noActiveChannel }
        
        let fileAttributes = NINLowLevelClientProps.initiate
        fileAttributes.set(name: attachment)
        
        let param = NINLowLevelClientProps.initiate
        param.set_sendFile()
        param.set(file: fileAttributes)
        param.set(channel: currentChannel)
        
        let payload = NINLowLevelClientPayload.initiate
        payload.append(data)
        
        do {
            let actionID = try session.send(param, payload)
            
            /// When this action completes, trigger the completion block callback
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
    
    /// Sends a message to the active channel. Active channel must exist.
    @discardableResult
    func send(type: MessageType, payload: [String:Any], completion: @escaping CompletionWithError) throws -> Int {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        guard let currentChannel = self.currentChannelID else { throw NINSessionExceptions.noActiveChannel }
        
        let param = NINLowLevelClientProps.initiate
        param.set_sendMessage()
        param.set(message: type.rawValue)
        param.set(channel: currentChannel)
        
        if type == .metadata, let _ = (payload["data"] as? [String:String])?["rating"] {
            param.set(recipients: NINLowLevelClientStrings.initiate)
            param.set(message: false)
        }
        
        if type.isRTC {
            /// Add message_ttl to all rtc signaling messages
            param.set(message: 10)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            
            let newPayload = NINLowLevelClientPayload.initiate
            newPayload.append(data)
            
            let actionID = try session.send(param, newPayload)
            
            /// When this action completes, trigger the completion block callback
            self.bind(action: actionID, closure: completion)
            return actionID
        } catch {
            completion(error)
            return -1
        }
    }
    
    func loadHistory(completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        guard let currentChannel = self.currentChannelID else { throw NINSessionExceptions.noActiveChannel }
        
        let param = NINLowLevelClientProps.initiate
        param.set_loadHistory()
        param.set(channel: currentChannel)
        
        do {
            let actionID = try session.send(param)
            
            /// When this action completes, trigger the completion block callback
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
}

// MARK: - NINChatSessionHelpers

extension NINChatSessionManagerImpl {
    // Asynchronously retrieves file info
    func describe(file id: String, completion: @escaping ((Error?, [String:Any]?) -> Void)) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        
        let param = NINLowLevelClientProps.initiate
        param.set_describeFile()
        param.set(file: id)
        
        do {
            let actionID = try session.send(param)
            self.onActionFileInfo = { id, fileInfo, error in
                guard id == actionID else { return }
                
                completion(error, fileInfo)
            }
        } catch {
            completion(error, nil)
        }
    }
    
    func translate(key: String, formatParams: [String:String]) -> String? {
        /// Look for a translation. If one is not available for this key, use the key itself.
        if let translationDictionary = self.siteConfiguration.translation {
            return formatParams.reduce(into: translationDictionary[key] ?? key, { translation, dict in
                translation = translation.replacingOccurrences(of: "{{\(dict.key)}}", with: dict.value)
            })
        }
        return nil
    }
}
