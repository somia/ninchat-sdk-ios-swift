//
// Copyright (c) 10.2.2023 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import JitsiMeetSDK

protocol NINGroupChatViewModel: AnyObject, NINChatStateProtocol, NINChatMessageProtocol, NINChatPermissionsProtocol, NINChatAttachmentProtocol {
    var hasJoinedVideo: Bool { get }

    var onChannelClosed: (() -> Void)? { get set }
    var onQueueUpdated: (() -> Void)? { get set }
    var onChannelMessage: ((MessageUpdateType) -> Void)? { get set }
    var onComposeActionUpdated: ((_ id: String, _ action: ComposeUIAction) -> Void)? { get set }
    var onGroupVideoReadyToClose: (() -> Void)? { get set }

    init(sessionManager: NINChatSessionManager)

    func joinVideoCall(inside parentView: UIView, completion: @escaping (Error?) -> Void)
    func leaveVideoCall()
}

final class NINGroupChatViewModelImpl: NSObject, NINGroupChatViewModel, JitsiMeetViewDelegate {
    private weak var sessionManager: NINChatSessionManager?
    private var pipViewCoordinator: PiPViewCoordinator?
    private var jitsiView: JitsiMeetView?
    private var typingStatus = false
    private var typingStatusQueue: DispatchWorkItem?
    private var isSelectingMedia = false

    var hasJoinedVideo: Bool {
        jitsiView?.delegate != nil
    }

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
    var onGroupVideoReadyToClose: (() -> Void)?

    init(sessionManager: NINChatSessionManager) {
        self.sessionManager = sessionManager

        super.init()

        self.setupListeners()
    }

    deinit {
        leaveVideoCall()
    }

    private func setupListeners() {
        self.sessionManager?.onChannelClosed = { [weak self] in
            self?.onChannelClosed?()
        }
        self.sessionManager?.bindQueueUpdate(closure: { [weak self] _, _, error in
            guard error == nil else {
                try? self?.sessionManager?.closeChat(endSession: true, onCompletion: nil)
                return
            }
            self?.onQueueUpdated?()
        }, to: self)
        self.sessionManager?.onMessageAdded = { [weak self] index in
            self?.onChannelMessage?(.insert(index))
        }
        self.sessionManager?.onHistoryLoaded = { [weak self] _ in
            self?.onChannelMessage?(.history)
        }
        self.sessionManager?.onMessageRemoved = { [weak self] index in
            self?.onChannelMessage?(.remove(index))
        }
        self.sessionManager?.onSessionDeallocated = { [weak self] in
            self?.onChannelMessage?(.clean)
        }
        self.sessionManager?.onComposeActionUpdated = { [weak self] id, action in
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

    func joinVideoCall(inside parentView: UIView, completion: @escaping (Error?) -> Void) {
        do {
            try sessionManager?.discoverJitsi { [weak self] result in
                guard let self = self, let sessionManager = self.sessionManager else {
                    return
                }
                switch result {
                case nil:
                    completion(NinchatError(type: "unknown", props: nil))
                case let .failure(error):
                    completion(error)
                case let .success(credentials):
                    var serverAddress: String = sessionManager.serverAddress
                    let apiPrefix = "api."
                    if serverAddress.hasPrefix(apiPrefix) {
                        let endIdx = serverAddress.index(serverAddress.startIndex, offsetBy: apiPrefix.count)
                        serverAddress.removeSubrange(serverAddress.startIndex ..< endIdx)
                    }
                    let jitsiServerAddress = "https://jitsi-www." + serverAddress
                    let options = JitsiMeetConferenceOptions.fromBuilder {
                        $0.serverURL = URL(string: jitsiServerAddress)
                        $0.room = credentials.room
                        $0.token = credentials.token
                        $0.setFeatureFlag("overflow-menu.enabled", withBoolean: true)
                        $0.setFeatureFlag("add-people.enabled", withBoolean: false)
                        $0.setFeatureFlag("calendar.enabled", withBoolean: false)
                        $0.setFeatureFlag("close-captions.enabled", withBoolean: false)
                        $0.setFeatureFlag("chat.enabled", withBoolean: false)
                        $0.setFeatureFlag("filmstrip.enabled", withBoolean: true)
                        $0.setFeatureFlag("invite.enabled", withBoolean: false)
                        $0.setFeatureFlag("kick-out.enabled", withBoolean: false)
                        $0.setFeatureFlag("live-streaming.enabled", withBoolean: false)
                        $0.setFeatureFlag("meeting-name.enabled", withBoolean: true)
                        $0.setFeatureFlag("meeting-password.enabled", withBoolean: false)
                        $0.setFeatureFlag("notifications.enabled", withBoolean: false)
                        $0.setFeatureFlag("recording.enabled", withBoolean: false)
                        $0.setFeatureFlag("welcomepage.enabled", withBoolean: false)
                        $0.setFeatureFlag("video-share.enabled", withBoolean: false)
                        $0.setFeatureFlag("toolbox.alwaysVisible", withBoolean: false)
                        $0.setFeatureFlag("fullscreen.enabled'", withBoolean: true)
                        $0.setFeatureFlag("help.enabled", withBoolean: false)
                        $0.setFeatureFlag("lobby-mode.enabled", withBoolean: false)
                        $0.setFeatureFlag("reactions.enabled", withBoolean: false)
                        $0.setFeatureFlag("prejoinpage.enabled", withBoolean: true)
                    }
                    let jitsiMeetView = self.jitsiView ?? JitsiMeetView()
                    jitsiMeetView.delegate = self
                    jitsiMeetView.join(options)

                    if self.pipViewCoordinator == nil {
                        self.pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
                    }
                    self.pipViewCoordinator?.configureAsStickyView(withParentView: parentView)

                    jitsiMeetView.alpha = 0

                    self.jitsiView = jitsiMeetView
                    self.pipViewCoordinator?.show()

                    completion(nil)
                }
            }
        } catch {
            completion(error)
        }
    }

    func leaveVideoCall() {
        leaveVideoCall(force: true)
    }

    private func leaveVideoCall(force: Bool) {
        guard hasJoinedVideo else {
            return
        }
        pipViewCoordinator?.hide()
        if force {
            jitsiView?.hangUp()
        }
        jitsiView?.delegate = nil
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
            try self.sessionManager?.send(message: message, completion: completion)
        } catch {
            completion(error)
        }
    }

    func send(action: ComposeContentViewProtocol, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager?.send(action: action, completion: completion)
        } catch {
            completion(error)
        }
    }

    func send(attachment: String, data: Data, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager?.send(attachment: attachment, data: data, completion: completion)
        } catch {
            completion(error)
        }
    }

    func send(type: MessageType, payload: [String:String], completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager?.send(type: type, payload: payload, completion: completion)
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

        try? self.sessionManager?.update(isWriting: state) { _ in  }
    }

    func loadHistory() {
        try? self.sessionManager?.loadHistory() { _ in }
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

// MARK: - Jitsi Delegate

extension NINGroupChatViewModelImpl {
    func ready(toClose data: [AnyHashable : Any]!) {
        leaveVideoCall(force: false)
        onGroupVideoReadyToClose?()
    }
}
