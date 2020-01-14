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
    case fileFound = "file_found"

    case queueFound = "realm_queues_found"
    
    case sessionCreated = "session_created"
    case userDeleted = "user_deleted"
    
    case audienceEnqueued = "audience_enqueued"
    case queueUpdated = "queue_updated"
}

protocol NINChatSessionManagerEventHandlers: class {
    var eventSessionHandler: NINLowLevelClientSessionEventHandlerProtocol! { get }
    var eventHandler: NINLowLevelClientEventHandlerProtocol! { get }
    var closeHandler: NINLowLevelClientCloseHandlerProtocol! { get}
    var logHandler: NINLowLevelClientLogHandlerProtocol! { get }
    var connHandler: NINLowLevelClientConnStateHandlerProtocol! { get }
    
    func onSessionEvent(param: NINLowLevelClientProps)
    func onEvent(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReplay: Bool)
    func onClose()
    func onLog(value: String)
    func onConnState(state: String)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerEventHandlers {
    var eventSessionHandler: NINLowLevelClientSessionEventHandlerProtocol! {
        return NINChatSessionManagerSessionEventHandler(session: self)
    }
    var eventHandler: NINLowLevelClientEventHandlerProtocol! {
        return NINChatSessionManagerEventHandler(session: self)
    }
    var closeHandler: NINLowLevelClientCloseHandlerProtocol! {
        return NINChatSessionManagerCloseHandler(session: self)
    }
    var logHandler: NINLowLevelClientLogHandlerProtocol! {
        return NINChatSessionManagerLogHandler(session: self)
    }
    var connHandler: NINLowLevelClientConnStateHandlerProtocol! {
        return NINChatSessionManagerConnHandler(session: self)
    }
    
    internal func setEventHandlers() {
        self.session?.setOnSessionEvent(eventSessionHandler)
        self.session?.setOnEvent(eventHandler)
        self.session?.setOnClose(closeHandler)
        self.session?.setOnLog(logHandler)
        self.session?.setOnConnState(connHandler)
    }
    
    func onSessionEvent(param: NINLowLevelClientProps) {
        do {
            let event = try param.event()
            if let eventType = Events(rawValue: event) {
                switch eventType {
                case .sessionCreated:
                    self.myUserID = try param.userID()
                    self.delegate?.log(value: "Session created - my user ID is: \(String(describing: self.myUserID))")
                    self.onActionSessionEvent?(eventType, nil)
                case .userDeleted:
                    try self.didDeleteUser(param: param)
                default:
                    break
                }
            }
        } catch {
            debugger("Error occured: \(error)")
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
                case .receivedMessage:
                    /// Throttle the message; it will be cached for a short while to ensure inbound message order.
                    messageThrottler?.add(NINInboundMessage(params: param, andPayload: payload))
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
            debugger("Error occured: \(error)")
        }
    }
    
    func onClose() {
        /// Nothing is here
    }
    
    func onLog(value: String) {
        /// Nothing is here
    }
    
    func onConnState(state: String) {
        /// Nothing is here
    }
}

/**
* These classes are used to work around circular reference memory leaks caused by the gomobile bind.
* They cannot hold a reference to 'proxy objects' ie. the ClientSession.
*/

final class NINChatSessionManagerSessionEventHandler: NSObject, NINLowLevelClientSessionEventHandlerProtocol {
    
    private weak var session: NINChatSessionManagerEventHandlers!
    
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    func onSessionEvent(_ params: NINLowLevelClientProps!) {
        DispatchQueue.main.async {
            self.session?.onSessionEvent(param: params)
        }
    }
}

final class NINChatSessionManagerEventHandler: NSObject, NINLowLevelClientEventHandlerProtocol {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    func onEvent(_ params: NINLowLevelClientProps!, payload: NINLowLevelClientPayload!, lastReply: Bool) {
        DispatchQueue.main.async {
            self.session?.onEvent(param: params, payload: payload, lastReplay: lastReply)
        }
    }
}
 
final class NINChatSessionManagerCloseHandler: NSObject, NINLowLevelClientCloseHandlerProtocol {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    func onClose() {
        DispatchQueue.main.async {
            self.session?.onClose()
        }
    }
}

final class NINChatSessionManagerLogHandler: NSObject, NINLowLevelClientLogHandlerProtocol {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    func onLog(_ msg: String!) {
        DispatchQueue.main.async {
            self.session?.onLog(value: msg)
        }
    }
}

final class NINChatSessionManagerConnHandler: NSObject, NINLowLevelClientConnStateHandlerProtocol {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    func onConnState(_ state: String!) {
        DispatchQueue.main.async {
            self.session?.onConnState(state: state)
        }
    }
}

