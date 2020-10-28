//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum MessageUpdateType {
    case insert(_ index: Int)
    case history
    case remove(_ index: Int)
    case clean
}

protocol NINChatRTCProtocol {
    typealias RTCCallReceive = (ChannelUser?) -> Void
    typealias RTCCallInitial = (Error?, NINChatWebRTCClient?) -> Void
    typealias RTCCallHangup = () -> Void
    
    func listenToRTCSignaling(delegate: NINChatWebRTCClientDelegate?, onCallReceived: @escaping RTCCallReceive, onCallInitiated: @escaping RTCCallInitial, onCallHangup: @escaping RTCCallHangup)
    func pickup(answer: Bool, completion: @escaping (Error?) -> Void)
    func hangup(completion: @escaping (Error?) -> Void)
    func disconnectRTC(_ client: NINChatWebRTCClient?, completion: (() -> Void)?)
}

protocol NINChatStateProtocol {
    func appDidEnterBackground(completion: @escaping (Error?) -> Void)
    func appWillResignActive(completion: @escaping (Error?) -> Void)
}

protocol NINChatMessageProtocol {
    func updateWriting(state: Bool)
    func send(message: String, completion: @escaping (Error?) -> Void)
    func send(action: ComposeContentViewProtocol, completion: @escaping (Error?) -> Void)
    func send(attachment: String, data: Data, completion: @escaping (Error?) -> Void)
    func send(type: MessageType, payload: [String:String], completion: @escaping (Error?) -> Void)
    func loadHistory(completion: @escaping (Error?) -> Void)
}

protocol NINChatPermissionsProtocol {
    func grantLibraryPermission(_ completion: @escaping (Error?) -> Void)
    func grantCameraPermission(_ completion: @escaping (Error?) -> Void)
}

protocol NINChatViewModel: NINChatRTCProtocol, NINChatStateProtocol, NINChatMessageProtocol, NINChatPermissionsProtocol {
    var onChannelClosed: (() -> Void)? { get set }
    var onQueueUpdated: (() -> Void)? { get set }
    var onChannelMessage: ((MessageUpdateType) -> Void)? { get set }
    var onComposeActionUpdated: ((_ index: Int, _ action: ComposeUIAction) -> Void)? { get set }
    
    init(sessionManager: NINChatSessionManager)
}

final class NINChatViewModelImpl: NINChatViewModel {
    private unowned var sessionManager: NINChatSessionManager
    var onChannelClosed: (() -> Void)?
    var onQueueUpdated: (() -> Void)?
    var onChannelMessage: ((MessageUpdateType) -> Void)?
    var onComposeActionUpdated: ((_ index: Int, _ action: ComposeUIAction) -> Void)?
    var pauseForPermissions: Bool = false

    init(sessionManager: NINChatSessionManager) {
        self.sessionManager = sessionManager
        
        self.setupListeners()
    }
    
    private func setupListeners() {
        self.sessionManager.onChannelClosed = { [weak self] in
            self?.onChannelClosed?()
        }
        self.sessionManager.bindQueueUpdate(closure: { [weak self] _, _, error in
            guard error == nil else { try? self?.sessionManager.closeChat(); return }
            self?.onQueueUpdated?()
        }, to: self)
        self.sessionManager.onMessageAdded = { [weak self] index in
            self?.onChannelMessage?(.insert(index))
        }
        self.sessionManager.onHistoryLoaded = { [weak self] _ in
            self?.onChannelMessage?(.history)
        }
        self.sessionManager.onMessageRemoved = { [weak self] index in
            self?.onChannelMessage?(.remove(index))
        }
        self.sessionManager.onSessionDeallocated = { [weak self] in
            self?.onChannelMessage?(.clean)
        }
        self.sessionManager.onComposeActionUpdated = { [weak self] index, action in
            self?.onComposeActionUpdated?(index, action)
        }
    }
}

// MARK: - NINChatRTC

extension NINChatViewModelImpl {
    func listenToRTCSignaling(delegate: NINChatWebRTCClientDelegate?, onCallReceived: @escaping RTCCallReceive, onCallInitiated: @escaping RTCCallInitial, onCallHangup: @escaping RTCCallHangup) {
        sessionManager.onRTCSignal = { [weak self] type, user, signal in
            switch type {
            case .call:
                debugger("WebRTC: call")
                onCallReceived(user)
            case .offer:
                /// Get access to camera and microphone before the call is initiated
                /// To resolve `https://github.com/somia/mobile/issues/281`
                debugger("WebRTC: offer, Check if the call can be initiated with current permissions\n")
                self?.grantVideoCallPermissions { error in
                    guard error == nil else { onCallInitiated(error, nil); return }

                    debugger("Permissions granted - initializing WebRTC for video call (answer)")
                    do {
                        try self?.sessionManager.beginICE { error, stunServers, turnServers in
                            do {
                                let client: NINChatWebRTCClient = NINChatWebRTCClientImpl(sessionManager: self?.sessionManager, operatingMode: .callee, stunServers: stunServers, turnServers: turnServers, delegate: delegate)
                                try client.start(with: signal)

                                onCallInitiated(error, client)
                            } catch {
                                onCallInitiated(error, nil)
                            }
                        }
                    } catch {
                        onCallInitiated(error, nil)
                    }
                }
            case .hangup:
                debugger("WebRTC: hang-up - closing the video call.")
                onCallHangup()
            default:
                break
            }
        }
    }
    
    func pickup(answer: Bool, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.send(type: .pickup, payload: ["answer": answer], completion: completion)
        } catch {
            completion(error)
        }
    }

    func hangup(completion: @escaping (Error?) -> Void) {
        debugger("hangup the call...")
        do {
            try self.sessionManager.send(type: .hangup, payload: [:], completion: completion)
        } catch {
            completion(error)
        }
    }

    func disconnectRTC(_ client: NINChatWebRTCClient?, completion: (() -> Void)?) {
        if let client = client {
            debugger("webRTC: disconnect resources")
            client.disconnect()
            completion?()
        }
    }
}

// MARK: - NINChatState

extension NINChatViewModelImpl {
    func appDidEnterBackground(completion: @escaping (Error?) -> Void) {
        guard !pauseForPermissions else { debugger("background for granting permissions, do not hangup"); return }

        debugger("background mode, hangup the video call (if there are any)")
        self.hangup(completion: completion)
    }
    
    func appWillResignActive(completion: @escaping (Error?) -> Void) {}
}

// MARK: - NINChatMessage

extension NINChatViewModelImpl {
    func send(message: String, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.send(message: message, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func send(action: ComposeContentViewProtocol, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.send(action: action, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func send(attachment: String, data: Data, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.send(attachment: attachment, data: data, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func send(type: MessageType, payload: [String:String], completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.send(type: type, payload: payload, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func updateWriting(state: Bool) {
        try? self.sessionManager.update(isWriting: state, completion: { _ in })
    }

    func loadHistory(completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.loadHistory(completion: completion)
        } catch {
            completion(error)
        }
    }
}

// MARK: - QueueUpdateCapture

extension NINChatViewModelImpl: QueueUpdateCapture {
    var desc: String {
        "NINChatViewModel"
    }
}

// MARK: - NINChatPermissionsProtocol

extension  NINChatViewModelImpl {
    private func grantVideoCallPermissions(_ completion: @escaping (Error?) -> Void) {
        pauseForPermissions = true
        Permission.grantPermission(.deviceCamera, .deviceMicrophone) { [weak self] error in
            debugger("permissions for video call granted with error: \(String(describing: error))")
            self?.pauseForPermissions = false; completion(error)
        }
    }

    func grantLibraryPermission(_ completion: @escaping (Error?) -> Void) {
        Permission.grantPermission(.devicePhotoLibrary) { error in
            completion(error)
        }
    }

    func grantCameraPermission(_ completion: @escaping (Error?) -> Void) {
        Permission.grantPermission(.deviceCamera) { error in
            completion(error)
        }
    }
}
