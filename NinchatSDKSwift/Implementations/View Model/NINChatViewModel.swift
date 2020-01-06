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
    typealias RTCCallReceive = ((NINChannelUser?) -> Void)
    typealias RTCCallInitial = ((Error?, NINWebRTCClient?) -> Void)
    typealias RTCCallHangup = (() -> Void)
    
    func listenToRTCSignaling(delegate: NINWebRTCClientDelegate, onCallReceived: @escaping RTCCallReceive, onCallInitiated: @escaping RTCCallInitial, onCallHangup: @escaping RTCCallHangup)
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
    func send(type: MessageType, payload: [String:String], completion: @escaping ((Error?) -> Void))
}

protocol NINChatViewModel: NINChatRTCProtocol, NINChatStateProtocol, NINChatMessageProtocol {
    var onChannelClosed: (() -> Void)? { get set }
    var onQueued: (() -> Void)? { get set }
    var onChannelMessage: ((MessageUpdateType) -> Void)? { get set }
    
    init(sessionManager: NINChatSessionManager)
}

final class NINChatViewModelImpl: NINChatViewModel {
    private unowned var sessionManager: NINChatSessionManager
    var signalingObserver: Any? = nil
    var messageObserver: Any? = nil
    var onChannelClosed: (() -> Void)?
    var onQueued: (() -> Void)?
    var onChannelMessage: ((MessageUpdateType) -> Void)?
    
    init(sessionManager: NINChatSessionManager) {
        self.sessionManager = sessionManager
        
        self.setupListeners()
    }
    
    private func setupListeners() {
        self.sessionManager.onChannelClosed = { [weak self] in
            self?.onChannelClosed?()
        }
        self.sessionManager.onQueueUpdated = { [weak self] event, queueID, position, error in
            if event == .queueUpdated {
                self?.onQueued?()
            }
        }
        self.sessionManager.onMessageAdded = { [weak self] index in
            self?.onChannelMessage?(.insert(index))
        }
        self.sessionManager.onMessageRemoved = { [weak self] index in
            self?.onChannelMessage?(.remove(index))
        }
    }
}

// MARK: - NINChatRTC

extension NINChatViewModelImpl {
    func listenToRTCSignaling(delegate: NINWebRTCClientDelegate, onCallReceived: @escaping RTCCallReceive, onCallInitiated: @escaping RTCCallInitial, onCallHangup: @escaping RTCCallHangup) {
        
        sessionManager.onRTCSignal = { [weak self] type, user, signal in
            switch type {
            case .call:
                debugger("Got WebRTC call")
                onCallReceived(user)
            
            case .offer:
                debugger("Got WebRTC offer - initializing webrtc for video call (answer)")
                
                do {
                    try self?.sessionManager.beginICE { error, stunServers, turnServers in
                        /// TODO: Update here
                        
//                            let client = NINWebRTCClient(sessionManager: self?.session.sessionManager, operatingMode: .callee, stunServers: stunServers, turnServers: turnServers)
//                            client?.delegate = delegate
//                            client?.start(withSDP: signal.sdp)
//                            onCallInitiated(error, client)
                    }
                } catch {
                    onCallInitiated(error, nil)
                }
            case .hangup:
                debugger("Got WebRTC hang-up - closing the video call.")
                onCallHangup()
            default:
                break
            }
        }
    }
    
    func pickup(answer: Bool, completion: @escaping ((Error?) -> Void)) {
        do {
            try self.sessionManager.send(type: .pickup, payload: ["answer": answer], completion: completion)
        } catch {
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
        do {
            try self.sessionManager.send(type: .hangup, payload: [:], completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func appWillResignActive(completion: @escaping ((Error?) -> Void)) {}
}

// MARK: - NINChatMessage

extension NINChatViewModelImpl {
    func send(message: String, completion: @escaping ((Error?) -> Void)) {
        do {
            try self.sessionManager.send(message: message, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func send(action: NINComposeContentView, completion: @escaping ((Error?) -> Void)) {
        do {
            try self.sessionManager.send(action: action, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func send(attachment: String, data: Data, completion: @escaping ((Error?) -> Void)) {
        do {
            try self.sessionManager.send(attachment: attachment, data: data, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func send(type: MessageType, payload: [String:String], completion: @escaping ((Error?) -> Void)) {
        do {
            try self.sessionManager.send(type: type, payload: payload, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func updateWriting(state: Bool) {
        try? self.sessionManager.update(isWriting: state, completion: { _ in })
    }
}
