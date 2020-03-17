//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

enum Events: String {
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

    case queueFound = "realm_queues_found"
    
    case sessionCreated = "session_created"
    case userDeleted = "user_deleted"
    
    case audienceEnqueued = "audience_enqueued"
    case queueUpdated = "queue_updated"
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
            let event = try param.event()
            print("session event handler: \(event)")
            if let eventType = Events(rawValue: event) {
                switch eventType {
                case .error:
                    self.onActionSessionEvent?(eventType, param.error())
                case .sessionCreated:
                    self.myUserID = param.userID()
                    self.delegate?.log(value: "Session created - my user ID is: \(String(describing: self.myUserID))")
                    self.onActionSessionEvent?(eventType, nil)
                case .userDeleted:
                    try self.didDeleteUser(param: param)
                default:
                    break
                }
            }
        } catch {
            debugger("Error occurred: \(error)")
        }
    }
    
    func onEvent(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReplay: Bool) {
        
        do {
            let event = try param.event()
            print("event handler: \(event)")
            if let eventType = Events(rawValue: event) {
                switch eventType {
                case .error:
                    try self.handlerError(param: param)
                case .channelJoined:
                    try self.didJoinChannel(param: param)
                case .receivedMessage, .historyResult:
                    /// Throttle the message; it will be cached for a short while to ensure inbound message order.
                    messageThrottler?.add(message: InboundMessage(params: param, payload: payload))
                case .queueFound:
                    try self.didRealmQueuesFind(param: param)
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

