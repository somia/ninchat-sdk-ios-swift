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
    func onSessionEvent(param: NINLowLevelClientProps)
    func onEvent(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReplay: Bool)
    func onClose()
    func onLog(value: String)
    func onConnState(state: String)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerEventHandlers {
    internal func setEventHandlers() {
        self.session?.setOnClose(NINChatSessionManagerCloseHandler(session: self))
        self.session?.setOnConnState(NINChatSessionManagerConnHandler(session: self))
        self.session?.setOnLog(NINChatSessionManagerLogHandler(session: self))
        self.session?.setOnEvent(NINChatSessionManagerEventHandler(session: self))
        self.session?.setOnSessionEvent(NINChatSessionManagerSessionEventHandler(session: self))
    }
    
    func onSessionEvent(param: NINLowLevelClientProps) {
        do {
            let event = try param.event()
            if let eventType = Events(rawValue: event) {
                switch eventType {
                case .sessionCreated:
                    self.myUserID = try param.userID()
                    self.sessionSwift.ninchat(sessionSwift, didOutputSDKLog: "Session created - my user ID is: \(String(describing: self.myUserID))")
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
                default:
                    break
                }
                
                /// Forward the event to the SDK
                self.sessionSwift.onLowLevelEvent?(sessionSwift, param, payload, lastReplay)
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

final class NINChatSessionManagerSessionEventHandler: NINLowLevelClientSessionEventHandler {
    
    private weak var session: NINChatSessionManagerEventHandlers!
    
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    override func onSessionEvent(_ params: NINLowLevelClientProps!) {
        DispatchQueue.main.async {
            self.session?.onSessionEvent(param: params)
        }
    }
}

final class NINChatSessionManagerEventHandler: NINLowLevelClientEventHandler {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    override func onEvent(_ params: NINLowLevelClientProps!, payload: NINLowLevelClientPayload!, lastReply: Bool) {
        DispatchQueue.main.async {
            self.session?.onEvent(param: params, payload: payload, lastReplay: lastReply)
        }
    }
}
 
final class NINChatSessionManagerCloseHandler: NINLowLevelClientCloseHandler {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    override func onClose() {
        DispatchQueue.main.async {
            self.session?.onClose()
        }
    }
}

final class NINChatSessionManagerLogHandler: NINLowLevelClientLogHandler {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    override func onLog(_ msg: String!) {
        DispatchQueue.main.async {
            self.session?.onLog(value: msg)
        }
    }
}

final class NINChatSessionManagerConnHandler: NINLowLevelClientConnStateHandler {
    
    private weak var session: NINChatSessionManagerEventHandlers?
       
    init(session: NINChatSessionManagerEventHandlers) {
        super.init()
        self.session = session
    }
    
    override func onConnState(_ state: String!) {
        DispatchQueue.main.async {
            self.session?.onConnState(state: state)
        }
    }
}

