//
// Copyright (c) 10.2.2023 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import JitsiMeetSDK

protocol NINGroupChatViewModel: AnyObject, NINChatStateProtocol, NINChatMessageProtocol, NINChatPermissionsProtocol, NINChatAttachmentProtocol {
    var onChannelClosed: (() -> Void)? { get set }
    var onQueueUpdated: (() -> Void)? { get set }
    var onChannelMessage: ((MessageUpdateType) -> Void)? { get set }
    var onComposeActionUpdated: ((_ id: String, _ action: ComposeUIAction) -> Void)? { get set }

    init(sessionManager: NINChatSessionManager)
}

final class NINGroupChatViewModelImpl: NINGroupChatViewModel {
    private unowned var sessionManager: NINChatSessionManager
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

// MARK: - NINChatState

extension NINGroupChatViewModelImpl {
    func willEnterBackground() {
        debugger("background mode, stop the video stream (if there are any)")
        /// instead of dropping the connection when the app goes to the background
        /// it is better to stop video stream and let the connection be alive
        /// discussed on `https://github.com/somia/mobile/issues/295`

        // TODO: Jitsi - think of PiP
//        self.disableVideoStream(disable: true)
    }

    func didEnterForeground() {
        /// take the video stream back

        // TODO: Jitsi - think of PiP
//        self.disableVideoStream(disable: false)

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

extension NINGroupChatViewModelImpl {
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

extension NINGroupChatViewModelImpl: QueueUpdateCapture {
    var desc: String {
        "NINGroupChatViewModel"
    }
}

// MARK: - NINChatPermissionsProtocol

extension NINGroupChatViewModelImpl {
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

extension NINGroupChatViewModelImpl {
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
