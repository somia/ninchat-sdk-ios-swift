//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import NinchatSDK

enum MessageUpdateType {
    case insert(_ index: Int)
    case remove(_ index: Int)
}

protocol NINChatRTCProtocol {
    var signalingObserver: Any? { get set } ///TODO:Should be refactored once observers are removed
    var messageObserver: Any? { get set } ///TODO:Should be refactored once observers are removed
    
    typealias RTCCallReceive = ((NINChannelUser?) -> Void)
    typealias RTCCallInitial = ((Error?, NINWebRTCClient?) -> Void)
    typealias RTCCallHangup = (() -> Void)
    func listenToRTCSignaling(delegate: NINWebRTCClientDelegate,
                              onCallReceived: @escaping RTCCallReceive,
                              onCallInitiated: @escaping RTCCallInitial,
                              onCallHangup: @escaping RTCCallHangup)
    func pickup(answer: Bool, completion: @escaping ((Error?) -> Void))
    func disconnectRTC(_ client: NINWebRTCClient?, completion: (() -> Void)?)
}

protocol NINChatStateProtocol {
    func appDidEnterBackground(completion: @escaping ((Error?) -> Void))
    func appWillResignActive(completion: @escaping ((Error?) -> Void))
}

protocol NINChatMessageProtocol {
    func updateWriting(state: Bool)
    func send(message: String, completion: @escaping ((Error?) -> Void))
    func send(action: NINComposeContentView, completion: @escaping ((Error?) -> Void))
    func send(attachment: String, data: Data, completion: @escaping ((Error?) -> Void))
    func send(type: String, payload: [String:String], completion: @escaping ((Error?) -> Void)) 
}

protocol NINChatViewModel: NINChatRTCProtocol, NINChatStateProtocol, NINChatMessageProtocol {
    var onChannelClosed: (() -> Void)? { get set }
    var onQueued: (() -> Void)? { get set }
    var onChannelMessage: ((MessageUpdateType) -> Void)? { get set }
    
    init(session: NINChatSessionSwift)
}

final class NINChatViewModelImpl: NINChatViewModel {
    private unowned let session: NINChatSessionSwift
    var signalingObserver: Any? = nil
    var messageObserver: Any? = nil
    var onChannelClosed: (() -> Void)?
    var onQueued: (() -> Void)?
    var onChannelMessage: ((MessageUpdateType) -> Void)?
    
    init(session: NINChatSessionSwift) {
        self.session = session
        self.setupListeners()
    }
    
    private func setupListeners() {
        fetchNotification(NotificationConstants.kNINChannelClosedNotification.rawValue) { [weak self] _ in
            self?.onChannelClosed?()
            return true
        }
        
        fetchNotification(NotificationConstants.kNINQueuedNotification.rawValue, { [weak self] notification -> Bool in
            if let event = notification.userInfo?["event"] as? String, event == "audience_enqueued" {
                self?.onQueued?()
                return true
            }
            return false
        })
        
        messageObserver = fetchNotification(NotificationConstants.kChannelMessageNotification.rawValue) { [weak self] notification -> Bool in
            #if DEBUG
            print("The message is received: \(notification)")
            #endif
            
            if let index = notification.userInfo?["index"] as? Int, let action = notification.userInfo?["action"] as? String {
                (action == "insert") ? self?.onChannelMessage?(.insert(index)) : self?.onChannelMessage?(.remove(index))
            }
            return false
        }
    }
}

// MARK: - NINChatRTC

extension NINChatViewModelImpl {
    func listenToRTCSignaling(delegate: NINWebRTCClientDelegate,
                              onCallReceived: @escaping RTCCallReceive,
                              onCallInitiated: @escaping RTCCallInitial,
                              onCallHangup: @escaping RTCCallHangup) {
        signalingObserver = fetchNotification(NotificationConstants.kNINWebRTCSignalNotification.rawValue) { [weak self] notification -> Bool in
            guard let messageType = notification.userInfo?["messageType"] as? String, let rtcType = WebRTCConstants(rawValue: messageType) else { return false }
            
            switch rtcType {
            case .kNINMessageTypeWebRTCCall:
                debugger("Got WebRTC call")
                onCallReceived(notification.userInfo?["messageUser"] as? NINChannelUser)
            case .kNINMessageTypeWebRTCOffer:
                debugger("Got WebRTC offer - initializing webrtc for video call (answer)")
                guard let offerPayload = notification.userInfo?["payload"] as? [String:Any], let sdp = offerPayload["sdp"] as? [AnyHashable:Any] else { return false }
                
                self?.session.sessionManager.beginICE { error, stunServers, turnServers in
                    let client = NINWebRTCClient(sessionManager: self?.session.sessionManager, operatingMode: .callee, stunServers: stunServers, turnServers: turnServers)
                    client?.delegate = delegate
                    client?.start(withSDP: sdp)
                    onCallInitiated(error, client)
                }
            case .kNINMessageTypeWebRTCHangup:
                debugger("Got WebRTC hang-up - closing the video call.")
                onCallHangup()
            default:
                break
            }
            return false
        }
    }
    
    func pickup(answer: Bool, completion: @escaping ((Error?) -> Void)) {
        self.session.sessionManager.sendMessage(withMessageType: WebRTCConstants.kNINMessageTypeWebRTCPickup.rawValue, payloadDict: ["answer": answer]) { error in
            completion(error)
        }
    }
    
    func disconnectRTC(_ client: NINWebRTCClient?, completion: (() -> Void)?) {
        if let client = client {
            debugger("Disconnecting webRTC resources")
            client.disconnect()
            completion?()
        }
    }
}

// MARK: - NINChatState

extension NINChatViewModelImpl {
    func appDidEnterBackground(completion: @escaping ((Error?) -> Void)) {
        session.sessionManager.sendMessage(withMessageType: WebRTCConstants.kNINMessageTypeWebRTCHangup.rawValue, payloadDict: [:]) { error in
            completion(error)
        }
    }
    
    func appWillResignActive(completion: @escaping ((Error?) -> Void)) {}
}

// MARK: - NINChatMessage

extension NINChatViewModelImpl {
    func send(message: String, completion: @escaping ((Error?) -> Void)) {
        self.session.sessionManager.sendTextMessage(message) { error in
            completion(error)
        }
    }
    
    func send(action: NINComposeContentView, completion: @escaping ((Error?) -> Void)) {
        self.session.sessionManager.sendUIActionMessage(action.composeMessageDict) { error in
            completion(error)
        }
    }
    
    func send(attachment: String, data: Data, completion: @escaping ((Error?) -> Void)) {
        self.session.sessionManager.sendFile(withFilename: attachment, with: data) { error in
            completion(error)
        }
    }
    
    func send(type: String, payload: [String:String], completion: @escaping ((Error?) -> Void)) {
        self.session.sessionManager.sendMessage(withMessageType: type, payloadDict: payload) { error in
            completion(error)
        }
    }
    
    func updateWriting(state: Bool) {
        self.session.sessionManager.setIsWriting(state) {_ in}
    }
}
