//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

enum Events: String {
    case channelFound = "channel_found"
    case channelJoined = "channel_joined"
    case channelUpdated = "channel_updated"
    case channelParted = "channel_parted"
    case channelMemberUpdated = "channel_member_updated"
    
    case error = "error"
    case iceBegun = "ice_begun"
    case userUpdated = "user_updated"
    case receivedMessage = "message_received"
    case historyResult = "history_results"
    case fileFound = "file_found"

    case realmQueueFound = "realm_queues_found"
    case queueFound = "queue_found"
    
    case sessionCreated = "session_created"
    case userDeleted = "user_deleted"
    
    case audienceEnqueued = "audience_enqueued"
    case queueUpdated = "queue_updated"

    case connectionSuperseded = "connection_superseded"
}

protocol NINChatSessionManagerEventHandlers {
    func onSessionEvent(param: NINLowLevelClientProps)
    func onEvent(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReplay: Bool)
    func onCloseEvent()
    func onLogEvent(value: String)
    func onConnStateEvent(state: String)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerEventHandlers {
    internal func setEventHandlers() {
        self.session?.setOnSessionEvent(self)
        self.session?.setOnEvent(self)
        self.session?.setOnClose(self)
        self.session?.setOnLog(self)
        self.session?.setOnConnState(self)
    }
    
    func onSessionEvent(param: NINLowLevelClientProps) {
        do {
            if case let .failure(error) = param.event { throw error }

            let event = param.event.value
            debugger("session event handler: \(event)")
            if let eventType = Events(rawValue: event) {
                switch eventType {
                case .error:
                    self.onActionSessionEvent?(nil, eventType, param.error)
                case .sessionCreated:
                    let credentials = try? NINSessionCredentials(params: param)
                    self.myUserID = credentials?.userID
                    self.delegate?.log(value: "Session created - my user ID is: \(String(describing: self.myUserID))")

                    /// Checks if the session is alive to resume
                    ///     is alive:
                    ///         1. update channel members (name, avatar, message threads, etc)
                    ///         2. describe channel's realm id (to get queues)
                    ///     is not alive
                    ///         1. notify to continue normal process.
                    if self.canResumeSession(param: param) {
                        try self.describe(channel: self.currentChannelID!) { error in
                            guard error == nil else { debugger("Error in describing the channel"); return }

                            try! self.describe(realm: self.realmID!, queuesID: self.siteConfiguration.audienceQueues) { error in
                                guard error == nil else { debugger("Error in describing the realm"); return }

                                self.didJoinChannel(channelID: self.currentChannelID!)
                                self.onActionSessionEvent?(credentials, eventType, nil)
                            }
                        }
                    } else {
                        self.onActionSessionEvent?(credentials, eventType, nil)
                    }
                case .userDeleted:
                    try self.didDeleteUser(param: param)
                default:
                    self.onActionSessionEvent?(nil, eventType, nil)
                }
            }
        } catch {
            debugger("Error occurred: \(error)")
        }
    }
    
    func onEvent(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReplay: Bool) {
        do {
            if case let .failure(error) = param.event { throw error }

            let event = param.event.value
            debugger("event handler: \(event)")
            if let eventType = Events(rawValue: event) {
                switch eventType {
                case .error:
                    try self.handlerError(param: param)
                case .channelJoined:
                    try self.didJoinChannel(param: param)
                case .historyResult:
                    try self.didLoadHistory(param: param)
                    fallthrough
                case .receivedMessage:
                    try self.didReceiveMessage(param: param, payload: payload)
                case .realmQueueFound:
                    try self.didFindRealmQueues(param: param)
                case .audienceEnqueued, .queueUpdated:
                    try self.didUpdateQueue(type: eventType, param: param)
                case .channelUpdated:
                    try self.didUpdateChannel(param: param)
                case .iceBegun:
                    try self.didBeginICE(param: param)
                case .userUpdated:
                    try self.didUpdateUser(param: param)
                case .channelParted:
                    try self.didPartChannel(param: param)
                case .channelMemberUpdated:
                    try self.didUpdateMember(param: param)
                case .fileFound:
                    try self.didFindFile(param: param)
                case .channelFound:
                    try self.didFindChannel(param: param)
                default:
                    break
                }
                
                /// Forward the event to the SDK
                self.delegate?.onLowLevelEvent(event: param, payload: payload, lastReply: lastReplay)
            }
        } catch {
            debugger("Error occurred: \(error)")
        }
    }
    
    func onCloseEvent() {
        /// Nothing is here
    }
    
    func onLogEvent(value: String) {
        /// Nothing is here
    }
    
    func onConnStateEvent(state: String) {
        /// Nothing is here
    }
}

extension NINChatSessionManagerImpl: NINLowLevelClientSessionEventHandlerProtocol {
    func onSessionEvent(_ params: NINLowLevelClientProps?) {
        DispatchQueue.main.async {
            self.onSessionEvent(param: params!)
        }
    }
}

extension NINChatSessionManagerImpl: NINLowLevelClientEventHandlerProtocol {
    func onEvent(_ params: NINLowLevelClientProps?, payload: NINLowLevelClientPayload?, lastReply: Bool) {
        DispatchQueue.main.async {
            self.onEvent(param: params!, payload: payload!, lastReplay: lastReply)
        }
    }
}

extension NINChatSessionManagerImpl: NINLowLevelClientCloseHandlerProtocol {
    func onClose() {
        DispatchQueue.main.async {
            self.onCloseEvent()
        }
    }
}

extension NINChatSessionManagerImpl: NINLowLevelClientLogHandlerProtocol {
    func onLog(_ msg: String?) {
        DispatchQueue.main.async {
            self.onLogEvent(value: msg!)
        }
    }
}

extension NINChatSessionManagerImpl: NINLowLevelClientConnStateHandlerProtocol {
    func onConnState(_ state: String?) {
        DispatchQueue.main.async {
            self.onConnStateEvent(state: state!)
        }
    }
}

