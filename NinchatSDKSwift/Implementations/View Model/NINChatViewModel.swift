//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import WebRTC

enum MessageUpdateType {
    case insert(_ index: Int)
    case history
    case remove(_ index: Int)
    case clean
}

protocol NINChatRTCProtocol {
    typealias RTCCallReceive = (ChannelUser?, Error?) -> Void
    typealias RTCCallInitial = (NINChatWebRTCClient?, Error?) -> Void
    typealias RTCCallHangup = () -> Void

    func listenToRTCSignaling(delegate: NINChatWebRTCClientDelegate?, onCallReceived: @escaping RTCCallReceive, onCallInitiated: @escaping RTCCallInitial, onCallHangup: @escaping RTCCallHangup)
    func pickup(answer: Bool, unsupported: Bool?, completion: @escaping (Error?) -> Void)
    func hangup(completion: @escaping (Error?) -> Void)
    func disconnectRTC(_ client: NINChatWebRTCClient?, completion: (() -> Void)?)
    func disableVideoStream(disable: Bool)
    func disableAudioStream(disable: Bool)
}
extension NINChatRTCProtocol {
    func pickup(answer: Bool, completion: @escaping (Error?) -> ()) {
        self.pickup(answer: answer, unsupported: nil, completion: completion)
    }
}

protocol NINChatStateProtocol {
    func willEnterBackground()
    func didEnterForeground()
}

protocol NINChatMessageProtocol {
    var onErrorOccurred: ((Error) -> Void)? { get set }

    func updateWriting(state: Bool)
    func send(message: String, completion: @escaping (Error?) -> Void)
    func send(action: ComposeContentViewProtocol, completion: @escaping (Error?) -> Void)
    func send(attachment: String, data: Data, completion: @escaping (Error?) -> Void)
    func send(type: MessageType, payload: [String:String], completion: @escaping (Error?) -> Void)
    func loadHistory()
}

protocol NINChatPermissionsProtocol {
    func grantVideoCallPermissions(_ completion: @escaping (Error?) -> Void)
}

protocol NINChatAttachmentProtocol {
    typealias AttachmentCompletion = (Error?) -> Void
    func openAttachment(source: UIImagePickerController.SourceType, completion: @escaping AttachmentCompletion)
}

protocol NINChatViewModel: AnyObject, NINChatRTCProtocol, NINChatStateProtocol, NINChatMessageProtocol, NINChatPermissionsProtocol, NINChatAttachmentProtocol {
    var onChannelClosed: (() -> Void)? { get set }
    var onQueueUpdated: (() -> Void)? { get set }
    var onChannelMessage: ((MessageUpdateType) -> Void)? { get set }
    var onComposeActionUpdated: ((_ id: String, _ action: ComposeUIAction) -> Void)? { get set }

    init(sessionManager: NINChatSessionManager)
}

final class NINChatViewModelImpl: NINChatViewModel {
    private unowned var sessionManager: NINChatSessionManager
    private var iceCandidates: [RTCIceCandidate] = []
    private var client: NINChatWebRTCClient?
    private var typingStatus = false
    private var typingStatusQueue: DispatchWorkItem?
    private var isSelectingMedia = false

    var backlogMessages: String? {
        didSet {
            if let backlogMessages = backlogMessages {
                self.send(message: backlogMessages) { _ in }
            }
        }
    }
    var onQueueUpdated: (() -> Void)?
    var onChannelClosed: (() -> Void)?
    var onErrorOccurred: ((Error) -> Void)?
    var onChannelMessage: ((MessageUpdateType) -> Void)?
    var onComposeActionUpdated: ((_ id: String, _ action: ComposeUIAction) -> Void)?

    init(sessionManager: NINChatSessionManager) {
        self.sessionManager = sessionManager

        self.setupListeners()
    }

    private func setupListeners() {
        self.sessionManager.onChannelClosed = { [weak self] in
            self?.onChannelClosed?()
        }
        self.sessionManager.bindQueueUpdate(closure: { [weak self] _, _, error in
            guard error == nil else {
                try? self?.sessionManager.closeChat(endSession: true, onCompletion: nil)
                return
            }
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
        self.sessionManager.onComposeActionUpdated = { [weak self] id, action in
            self?.onComposeActionUpdated?(id, action)
        }
    }

    private func startTimer() {
        self.typingStatusQueue = DispatchWorkItem { [weak self] in
            self?.updateWriting(state: false)
        }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(20), execute: self.typingStatusQueue!)
    }

    private func cancelTimer() {
        self.typingStatusQueue?.cancel()
    }
}

// MARK: - NINChatRTC

extension NINChatViewModelImpl {
    func listenToRTCSignaling(delegate: NINChatWebRTCClientDelegate?, onCallReceived: @escaping RTCCallReceive, onCallInitiated: @escaping RTCCallInitial, onCallHangup: @escaping RTCCallHangup) {
        sessionManager.onRTCClientSignal = { [weak self] type, user, signal in
            debugger("WebRTC: Client Signal: \(type)")
            guard type == .candidate else { return }

            /// Queue received candidates and inject during initialization
            guard let iceCandidate = signal?.candidate?.toRTCIceCandidate else { return }
            debugger("WebRTC: Adding \(iceCandidate) to queue")
            self?.iceCandidates.append(iceCandidate)
        }

        sessionManager.onRTCSignal = { [weak self] type, user, signal in
            switch type {
            case .call:
                debugger("WebRTC: call")
                onCallReceived(user, nil)
            case .offer:
                do {
                    try self?.sessionManager.beginICE { error, stunServers, turnServers in
                        do {
                            self?.client = NINChatWebRTCClientImpl(sessionManager: self?.sessionManager, operatingMode: .callee, stunServers: stunServers, turnServers: turnServers, candidates: self?.iceCandidates, delegate: delegate)
                            try self?.client?.start(with: signal)

                            onCallInitiated(self?.client, error)
                        } catch {
                            onCallInitiated(nil, error)
                        }
                    }
                } catch {
                    onCallInitiated(nil, error)
                }
            case .hangup:
                debugger("WebRTC: hang-up - closing the video call.")
                onCallHangup()
            default:
                break
            }
        }
    }

    func pickup(answer: Bool, unsupported: Bool? = nil, completion: @escaping (Error?) -> Void) {
        do {
            var payload = ["answer": answer]
            if unsupported != nil {
                payload["unsupported"] = unsupported
            }

            try self.sessionManager.send(type: .pickup, payload: payload, completion: completion)
        } catch {
            completion(error)
        }
    }

    func hangup(completion: @escaping (Error?) -> Void) {
        guard self.client != nil else { debugger("No WebRTC is available, skip hangup instruction"); completion(nil); return }

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
    
    func disableVideoStream(disable: Bool) {
        self.client?.disableLocalVideo = disable
    }
    
    func disableAudioStream(disable: Bool) {
        self.client?.disableLocalAudio = disable
    }
}

// MARK: - NINChatState

extension NINChatViewModelImpl {
    func willEnterBackground() {
        debugger("background mode, stop the video stream (if there are any)")
        /// instead of dropping the connection when the app goes to the background
        /// it is better to stop video stream and let the connection be alive
        /// discussed on `https://github.com/somia/mobile/issues/295`
        self.disableVideoStream(disable: true)
    }

    func didEnterForeground() {
        /// take the video stream back
        self.disableVideoStream(disable: false)

        /// reload history if the app was in the background
        ///
        /// this is a workaround to avoid missing messages
        /// when the app is in the background, and the OS decides
        /// to close the connection, or if the user gets suspended
        /// and not deleted.
        ///
        /// if the user was deleted when the app gets back in the
        /// foreground, the solution we have developed for the issue
        /// `https://github.com/somia/mobile/issues/368`
        /// is followed
        ///
        /// however, if there is still problems in case the user
        /// was deleted when the app gets back in foreground (such
        /// as race conditions in loading history or checking the
        /// user's status), and if the new issue is critical to resolve,
        /// then a dedicated task must be opened to investigate the
        /// problem.
        /// Update: the history shall not be loaded if the user
        /// is just selecting a media to send. Either if they choose
        /// or cancel, the backlog doesn't need to be updated with history
        /// reload.

        if !self.isSelectingMedia {
            debugger("getting back to foreground, reloading history")
            self.loadHistory()
        }
        self.isSelectingMedia = false
    }
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
        self.cancelTimer()

        if state {
            /// restart timer if user is still typing
            self.startTimer()
        }

        if typingStatus == state {
            /// skip if the status has not changed
            return
        }
        self.typingStatus = state

        try? self.sessionManager.update(isWriting: state) { _ in  }
    }

    func loadHistory() {
        try? self.sessionManager.loadHistory() { _ in }
    }
}

// MARK: - QueueUpdateCapture

extension NINChatViewModelImpl: QueueUpdateCapture {
    var desc: String {
        "NINChatViewModel"
    }
}

// MARK: - NINChatPermissionsProtocol

extension NINChatViewModelImpl {
    func grantVideoCallPermissions(_ completion: @escaping (Error?) -> Void) {
        Permission.grantPermission(.deviceCamera, .deviceMicrophone) { error in
            debugger("permissions for video call granted with error: \(String(describing: error))")
            completion(error)
        }
    }

    private func grantLibraryPermission(_ completion: @escaping (Error?) -> Void) {
        Permission.grantPermission(.devicePhotoLibrary) { error in
            completion(error)
        }
    }

    private func grantCameraPermission(_ completion: @escaping (Error?) -> Void) {
        Permission.grantPermission(.deviceCamera) { error in
            completion(error)
        }
    }
}

// MARK: - NINChatAttachmentProtocol

extension NINChatViewModelImpl {
    func openAttachment(source: UIImagePickerController.SourceType, completion: @escaping AttachmentCompletion) {
        self.isSelectingMedia = true

        switch source {
        case .photoLibrary:
            self.grantLibraryPermission { error in
                completion(error)
            }
        case .camera:
            self.grantCameraPermission { error in
                completion(error)
            }
        default:
            fatalError("The source cannot be anything else")
        }
    }
}
