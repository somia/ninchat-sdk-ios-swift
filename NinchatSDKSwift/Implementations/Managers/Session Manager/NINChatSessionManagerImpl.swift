//
// Copyright (c) 26.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import Foundation
import NinchatLowLevelClient

protocol NINChatSessionManagerInternalActions {
    var onActionSessionEvent: ((NINSessionCredentials?, Events, Error?) -> Void)? { get set }
    var onProgress: ((Queue, _ position: Int, Events, Error?) -> Void)? { get set }
    var onActionID: ((_ actionID: NINResult<Int>, Error?) -> Void)? { get set }
    var onChannelJoined: Completion? { get set }
    var onActionSevers: ((_ actionID: NINResult<Int>, _ stunServers: [WebRTCServerInfo]?, _ turnServers: [WebRTCServerInfo]?) -> Void)? { get set }
    var onActionFileInfo: ((_ actionID: NINResult<Int>, _ fileInfo: [String:Any]?, Error?) -> Void)? { get set }
    var onActionChannel: ((_ actionID: NINResult<Int>, _ channelID: String) -> Void)? { get set }
    var didEndSession: (() -> Void)? { get set }
}

final class NINChatSessionManagerImpl: NSObject, NINChatSessionManager, NINChatDevHelper, NINChatSessionManagerInternalActions {
    internal var serviceManager = ServiceManager()
    internal var channelUsers: [String:ChannelUser] = [:]
    internal var currentQueueID: String?
    internal var currentChannelID: String?
    internal var backgroundChannelID: String?
    internal var myUserID: String?
    internal var channelClosed: Bool = false
    internal var expectedHistoryLength = -1

    // MARK: - NINChatSessionManagerInternalActions
    
    internal var onActionSessionEvent: ((NINSessionCredentials?, Events, Error?) -> Void)?
    internal var onProgress: ((Queue, Int, Events, Error?) -> Void)?
    internal var onActionID: ((NINResult<Int>, Error?) -> Void)?
    internal var onChannelJoined: Completion?
    internal var onActionSevers: ((NINResult<Int>, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void)?
    internal var onActionFileInfo: ((NINResult<Int>, [String:Any]?, Error?) -> Void)?
    internal var onActionChannel: ((NINResult<Int>, String) -> Void)?
    internal var didEndSession: (() -> Void)?
    
    // MARK: - NINChatSessionManagerClosureHandler

    internal var actionBoundClosures: [Int: (Error?) -> Void] = [:]
    internal var actionFileBoundClosures: [Int: (Error?, [String:Any]?) -> Void] = [:]
    internal var actionChannelBoundClosures: [Int: (Error?) -> Void] = [:]
    internal var actionICEServersBoundClosures: [Int: (Error?, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void] = [:]
    internal var queueUpdateBoundClosures: [String: (Events, Queue, Error?) -> Void] = [:]

    // MARK: - NINChatSessionConnectionManager variables
    
    var session: NINLowLevelClientSession?
    var connected: Bool! {
        self.session != nil
    }

    // MARK: - NINChatSessionManager variables
    
    var realmID: String?
    var chatMessages: [ChatMessage]! = []
    var describedQueue: Queue?
    var agent: ChannelUser?
    var composeActions: [ComposeUIAction] = []
    
    // MARK: - NINChatSessionManagerDelegate

    var onMessageAdded: ((_ index: Int) -> Void)?
    var onMessageRemoved: ((_ index: Int) -> Void)?
    var onHistoryLoaded: ((_ length: Int) -> Void)?
    var onSessionDeallocated: (() -> Void)?
    var onChannelClosed: (() -> Void)?
    var onRTCSignal: ((MessageType, ChannelUser?, _ signal: RTCSignal?) -> Void)?
    var onRTCClientSignal: ((MessageType, ChannelUser?, _ signal: RTCSignal?) -> Void)?
    var onComposeActionUpdated: ((_ id: String, _ action: ComposeUIAction) -> Void)?
    
    func bindQueueUpdate<T: QueueUpdateCapture>(closure: @escaping (Events, Queue, Error?) -> Void, to receiver: T) {
        guard queueUpdateBoundClosures.keys.filter({ $0 == receiver.desc }).count == 0 else { return }
        queueUpdateBoundClosures[receiver.desc] = closure
    }

    func unbindQueueUpdateClosure<T: QueueUpdateCapture>(from receiver: T) {
        self.queueUpdateBoundClosures.removeValue(forKey: receiver.desc)
    }

    // MARK: - NINChatSessionManager
    
    private(set) weak var audienceMetadata: NINLowLevelClientProps? {
        set {
            NINLowLevelClientProps.saveMetadata(newValue)
        }
        get {
            NINLowLevelClientProps.loadMetadata()
        }
    }
    weak var delegate: NINChatSessionInternalDelegate?
    var queues: [Queue]! = [] {
        didSet {
            self.audienceQueues = self.queues
        }
    }
    var audienceQueues: [Queue]! = []
    var siteConfiguration: SiteConfiguration!
    var givenConfiguration: NINSiteConfiguration?
    weak var preAudienceQuestionnaireMetadata: NINLowLevelClientProps! {
        didSet {
            let metadata = self.audienceMetadata ?? NINLowLevelClientProps()
            metadata.set(value: preAudienceQuestionnaireMetadata, forKey: "pre_answers")
            
            /// Since metadata is loaded from the UserDefaults instead of memory,
            /// it is necessary to update its value after pre_answers are set
            NINLowLevelClientProps.saveMetadata(metadata)
        }
    }
    var appDetails: String?
    
    // MARK: - NINChatSessionManagerDevTools
    
    var serverAddress: String!
    var siteSecret: String?
    
    init(session: NINChatSessionInternalDelegate?, serverAddress: String, audienceMetadata: NINLowLevelClientProps? = nil, configuration: NINSiteConfiguration?) {
        super.init()

        self.delegate = session
        self.serverAddress = serverAddress
        self.givenConfiguration = configuration
        self.audienceMetadata = audienceMetadata
    }
    
    /** Designed for test and internal purposes. */
    convenience init(session: NINChatSessionInternalDelegate?, serverAddress: String, siteSecret: String?, audienceMetadata: NINLowLevelClientProps? = nil, configuration: NINSiteConfiguration? = nil) {
        self.init(session: session, serverAddress: serverAddress, audienceMetadata: audienceMetadata, configuration: configuration)
        self.siteSecret = siteSecret
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
        let request = SiteConfigRequest(serverAddress: self.serverAddress, configKey: key)
        
        self.serviceManager.perform(request) { [weak self] result in
            guard let `self` = self else { return }
            
            switch result {
            case .success(let config):
                debugger("Got site config: \(String(describing: config.toDictionary))")
                self.siteConfiguration = SiteConfigurationImpl(configuration: config.toDictionary, environments: environments)
                self.siteConfiguration.override(configuration: self.givenConfiguration)
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func openSession(completion: @escaping CompletionWithCredentials) throws {
        delegate?.log(value: "Opening new chat session using server address: \(serverAddress!)")
        try self.initiateSession(params: NINLowLevelClientProps.initiate(), completion: completion)
    }

    func continueSession(credentials: NINSessionCredentials, completion: @escaping CompletionWithCredentials) throws {
        delegate?.log(value: "Resume session using user ID: \(credentials.userID)")
        try self.initiateSession(params: NINLowLevelClientProps.initiate(credentials: credentials), completion: completion)
    }

    internal func initiateSession(params: NINLowLevelClientProps, completion: @escaping CompletionWithCredentials) throws {
        /// Wait for the session creation event
        self.onActionSessionEvent = { [weak self] credentials, event, error in
            guard let `self` = self else { return }
            
            if event == .sessionCreated {
                if self.currentChannelID != nil {
                    completion(credentials, .toChannel, error); return
                }
                if let queueID = self.currentQueueID {
                    completion(credentials, .toQueue(self.queues.first(where: { $0.queueID == queueID })), error); return
                }
                completion(credentials, nil, error)
            } else if event == .error {
                completion(nil, nil, error)
            }
        }

        /// Make sure our site configuration contains a realm_id
        guard let realmId = self.siteConfiguration?.audienceRealm else {
            throw NINSessionExceptions.invalidRealmConfiguration
        }
        self.realmID = realmId

        if let secret = self.siteSecret {
            params.siteSecret = .success(secret)
        }

        if let userName = self.siteConfiguration.userName {
            params.userAttributes = .success(NINLowLevelClientProps.initiate(name: userName))
        }

        let messageType = NINLowLevelClientStrings()
        messageType.append(MessageType.file.rawValue)
        messageType.append(MessageType.text.rawValue)
        messageType.append(MessageType.metadata.rawValue)
        messageType.append(MessageType.rtc.rawValue)
        messageType.append(MessageType.ui.rawValue)
        messageType.append(MessageType.info.rawValue)
        params.messageTypes = .success(messageType)

        self.session = NINLowLevelClientSession()
        self.session?.setAddress(self.serverAddress)
        self.session?.setHeader("User-Agent", value: self.sdkDetails)
        self.setEventHandlers()

        try self.session?.setParams(params)
        try self.session?.open()
    }

    func describe(queuesID: [String]?, completion: @escaping CompletionWithError) throws {
        guard let realmID = self.realmID, let session = self.session else { throw NINSessionExceptions.noActiveSession }

        let param = NINLowLevelClientProps.initiate(action: .describeRealmQueues)
        param.realmID = .success(realmID)
        
        if let queuesID = queuesID {
            /// Parameter should be set only if there are any queues passed to the function
            param.queuesID = .success(queuesID.reduce(into: NINLowLevelClientStrings()) { list, id in
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
    
    func join(queue ID: String, progress: @escaping (Queue?, Error?, Int) -> Void, completion: @escaping Completion) throws {
        
        func performJoin() throws {
            delegate?.log(value: "Joining queue \(ID)..")
            self.onChannelJoined = {
                /// According to https://github.com/somia/mobile/issues/287
                /// Clear metadata from the UserDefaults on a successful join
                UserDefaults.remove(forKey: .metadata)

                completion()
            }
            
            /// Check if we are already in an active queue
            if self.currentQueueID == nil {
                guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
                
                let param = NINLowLevelClientProps.initiate(action: .requestAudience)
                param.queueID = .success(ID)

                if let audienceMetadata = self.audienceMetadata {
                    param.metadata = .success(audienceMetadata)
                }
                do {
                    _ = try session.send(param)
                } catch {
                    progress(nil, error, -1)
                }
            }

            self.onProgress = { [weak self] queue, position, event, error in
                if (event == .queueUpdated || event == .audienceEnqueued), self?.currentQueueID == queue.queueID {
                    progress(queue, error, position)
                }
            }
        }
        
        if let currentChannel = self.currentChannelID {
            delegate?.log(value: "Parting current channel first")
            
            try self.part(channel: currentChannel) { [weak self] error in
                self?.delegate?.log(value: "Channel parted; joining queue.")
                self?.backgroundChannelID = self?.currentChannelID
                self?.currentChannelID = nil
                try? performJoin()
            }
        } else {
            try performJoin()
        }
    }
    
    /// Deallocate a session by resetting local variables.
    func deallocateSession() {
        delegate?.log(value: "Session deallocation by resetting local variable")
        self.onProgress = nil
        self.onChannelJoined = nil
        self.onActionID = nil
        self.onActionChannel = nil
        self.onActionFileInfo = nil
        self.onActionSessionEvent = nil
        self.onActionSevers = nil

        self.actionBoundClosures.keys.forEach { self.actionBoundClosures.removeValue(forKey: $0) }
        self.queueUpdateBoundClosures.keys.forEach { self.queueUpdateBoundClosures.removeValue(forKey: $0) }
        self.actionICEServersBoundClosures.keys.forEach { self.actionICEServersBoundClosures.removeValue(forKey: $0) }
        self.actionChannelBoundClosures.keys.forEach { self.actionChannelBoundClosures.removeValue(forKey: $0) }
        self.actionFileBoundClosures.keys.forEach({ self.actionFileBoundClosures.removeValue(forKey: $0) })
        self.chatMessages.removeAll()
        self.channelUsers.removeAll()
        self.queues.removeAll()

        self.onRTCClientSignal = nil
        self.onRTCSignal = nil

        self.backgroundChannelID = nil
        self.currentChannelID = nil
        self.currentQueueID = nil
        self.myUserID = nil

        if self.session != nil {
            do {
                try self.closeChat()
            } catch {
                self.disconnect()
            }
        }
        self.onSessionDeallocated?()
    }
    
    /// Retrieves the WebRTC ICE STUN/TURN server details
    func beginICE(completion: @escaping (Error?, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        let param = NINLowLevelClientProps.initiate(action: .beginICE)
        
        do {
            let actionID = try session.send(param)
            self.bindICEServer(action: actionID, closure: completion)
        } catch {
            completion(error, nil, nil)
        }
    }
    
    /// Register audience questionnaire answers
    func registerAudience(queue ID: String, answers: NINLowLevelClientProps, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }

        let param = NINLowLevelClientProps.initiate(action: .registerAudience)
        param.queueID = .success(ID)
        param.metadata = .success(answers)

        do {
            let actionID = try session.send(param)
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }

    /// Low-level shutdown of the chat's session; invalidates session resource.
    func closeChat(onCompletion: Completion? = nil) throws {
        delegate?.log(value: "Shutting down chat Session..")

        func endSession() {
            self.disconnect()

            /// Signal the delegate that our session has ended
            self.delegate?.onDidEnd()
            self.didEndSession?()
            onCompletion?()
        }

        if self.myUserID == nil {
            endSession()
        } else if let userID = self.myUserID, let user = self.channelUsers[userID], !user.guest {
            endSession()
        } else {
            try self.deleteCurrentUser { error in
                endSession()
            }
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

    /// Closes the old session using the session_id. The result can be ignored.
    func closeSession(credentials: NINSessionCredentials, completion: ((NINResult<Empty>) -> Void)?) {
        let request = CloseSession(url: self.serverAddress, credentials: credentials, siteSecret: self.siteSecret)
        self.serviceManager.perform(request) { result in
            completion?(result)
        }
    }
}

// MARK: - NINChatSessionMessenger

extension NINChatSessionManagerImpl {
    func update(isWriting: Bool, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        guard let currentChannel = self.currentChannelID else { throw NINSessionExceptions.noActiveQueue }
        guard let userID = self.myUserID else { throw NINSessionExceptions.noActiveUserID }
        
        let memberAttributes = NINLowLevelClientProps.initiate()
        memberAttributes.writing = .success(isWriting)
        
        let param = NINLowLevelClientProps.initiate(action: .updateMember)
        param.channelID = .success(currentChannel)
        param.userID = .success(userID)
        param.channelMemberAttributes = .success(memberAttributes)
        
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
    func send(action: ComposeContentViewProtocol, completion: @escaping CompletionWithError) throws {
        guard self.session != nil else { throw NINSessionExceptions.noActiveSession }
        
        try self.send(type: .uiAction, payload: ["action": "click", "target": action.messageDictionary], completion: completion)
    }
    
    func send(attachment: String, data: Data, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        guard let currentChannel = self.currentChannelID else { throw NINSessionExceptions.noActiveChannel }
        
        let fileAttributes = NINLowLevelClientProps.initiate(name: attachment)
        let param = NINLowLevelClientProps.initiate(action: .sendFile)
        param.fileAttributes = .success(fileAttributes)
        param.channelID = .success(currentChannel)
        
        let payload = NINLowLevelClientPayload()
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
    func send(type: MessageType, payload: [String:Any], completion: @escaping CompletionWithError) throws -> Int? {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        guard let currentChannel = self.currentChannelID else { throw NINSessionExceptions.noActiveChannel }
        
        let param = NINLowLevelClientProps.initiate(action: .sendMessage)
        param.messageType = .success(type)
        param.channelID = .success(currentChannel)
        
        if type == .metadata, let _ = (payload["data"] as? [String:Int])?["rating"] {
            param.recipients = .success(NINLowLevelClientStrings())
            param.messageFold = .success(true)
        }
        
        if type.isRTC {
            /// Add message_ttl to all rtc signaling messages
            param.messageTTL = .success(10)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            let newPayload = NINLowLevelClientPayload()
            newPayload.append(data)
            
            let actionID = try session.send(param, newPayload)
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
        
        let param = NINLowLevelClientProps.initiate(action: .loadHistory)
        param.channelID = .success(currentChannel)
        param.historyOrder = .success(HistoryOrder.DESC.rawValue)

        /// Currently we need to just load supported message types
        let messageType = NINLowLevelClientStrings()
        messageType.append(MessageType.file.rawValue)
        messageType.append(MessageType.text.rawValue)
        messageType.append(MessageType.ui.rawValue)
        param.messageTypes = .success(messageType)

        do {
            let actionID = try session.send(param)
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
}

// MARK: - NINChatSessionHelpers

extension NINChatSessionManagerImpl {
    // Asynchronously retrieves file info
    func describe(file id: String, completion: @escaping (Error?, [String:Any]?) -> Void) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        let param = NINLowLevelClientProps.initiate(action: .describeFile)
        param.fileID = .success(id)

        do {
            /// In case of getting multiple files to describe, the actionID points to the latest id only
            /// This could cause to lose of previous files to be described
            let actionID = try session.send(param)
            self.bindFile(action: actionID, closure: completion)
        } catch {
            completion(error, nil)
        }
    }

    func describe(channel id: String, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }

        let param = NINLowLevelClientProps.initiate(action: .describeChannel)
        param.channelID = .success(id)

        do {
            let actionID = try session.send(param)
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }

    func translate(key: String, formatParams: [String:String]) -> String? {
        /// Look for a translation. If one is not available for this key, use the key itself.
        return formatParams.reduce(into: self.siteConfiguration.translation?[key] ?? key, { translation, dict in
            translation = translation.replacingOccurrences(of: "{{\(dict.key)}}", with: dict.value)
        })
    }
}
