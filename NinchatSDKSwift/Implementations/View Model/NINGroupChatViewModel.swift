//
// Copyright (c) 10.2.2023 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import WebKit
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
    func joinWebVideoCall(inside parentView: UIView, completion: @escaping (Error?) -> Void)
    func leaveVideoCall()
}

final class NINGroupChatViewModelImpl: NSObject, NINGroupChatViewModel, JitsiMeetViewDelegate {
    private weak var sessionManager: NINChatSessionManager?
    private var pipViewCoordinator: PiPViewCoordinator?
    private var jitsiView: JitsiMeetView?
    private var webView: WKWebView?
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
        self.sessionManager?.onMessageUpdated = { [weak self] index in
            self?.onChannelMessage?(.update(index))
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
                    let avatarConfig = AvatarConfig(forUser: sessionManager)
                    let user = sessionManager.myUser
                    let iconURL = avatarConfig.imageOverrideURL ?? user?.iconURL
                    let userName = !avatarConfig.nameOverride.isEmpty
                        ? avatarConfig.nameOverride
                        : (user?.displayName ?? "Guest".localized)

                    var serverAddress: String = sessionManager.serverAddress
                    let apiPrefix = "api."
                    if serverAddress.hasPrefix(apiPrefix) {
                        let endIdx = serverAddress.index(serverAddress.startIndex, offsetBy: apiPrefix.count)
                        serverAddress.removeSubrange(serverAddress.startIndex ..< endIdx)
                    }
                    let jitsiServerAddress = "https://jitsi-www." + serverAddress
                    let options = JitsiMeetConferenceOptions.fromBuilder {
                        $0.serverURL = URL(string: jitsiServerAddress)
                        $0.userInfo = .init(
                            displayName: userName,
                            andEmail: nil,
                            andAvatar: iconURL.flatMap { URL(string: $0) }
                        )
                        $0.room = credentials.room
                        $0.token = credentials.token

                        $0.setFeatureFlag("add-people.enabled", withBoolean: false)
                        $0.setFeatureFlag("audio-mute.enabled", withBoolean: true)
                        $0.setFeatureFlag("calendar.enabled", withBoolean: false)
                        $0.setFeatureFlag("call-integration.enabled", withBoolean: true) // android: false
                        $0.setFeatureFlag("car-mode.enabled", withBoolean: false)
                        $0.setFeatureFlag("close-captions.enabled", withBoolean: false)
                        $0.setFeatureFlag("conference-timer.enabled", withBoolean: true)
                        $0.setFeatureFlag("chat.enabled", withBoolean: false)
                        $0.setFeatureFlag("filmstrip.enabled", withBoolean: true)
                        $0.setFeatureFlag("fullscreen.enabled", withBoolean: true)
                        $0.setFeatureFlag("invite.enabled", withBoolean: false)
                        $0.setFeatureFlag("ios.screensharing.enabled", withBoolean: false)
                        $0.setFeatureFlag("speakerstats.enabled", withBoolean: false)
                        $0.setFeatureFlag("kick-out.enabled", withBoolean: false)
                        $0.setFeatureFlag("live-streaming.enabled", withBoolean: false)
                        $0.setFeatureFlag("meeting-name.enabled", withBoolean: false)
                        $0.setFeatureFlag("meeting-password.enabled", withBoolean: false)
                        $0.setFeatureFlag("notifications.enabled", withBoolean: false)
                        $0.setFeatureFlag("overflow-menu.enabled", withBoolean: true)
                        $0.setFeatureFlag("pip.enabled", withBoolean: false)
                        $0.setFeatureFlag("pip-while-screen-sharing.enabled", withBoolean: false)
                        $0.setFeatureFlag("prejoinpage.enabled", withBoolean: true)
                        $0.setFeatureFlag("prejoinpage.hide-display-name.enabled", withBoolean: true)
                        $0.setFeatureFlag("raise-hand.enabled", withBoolean: false)
                        $0.setFeatureFlag("recording.enabled", withBoolean: false)
                        $0.setFeatureFlag("server-url-change.enabled", withBoolean: false)
                        $0.setFeatureFlag("settings.enabled", withBoolean: true)
                        $0.setFeatureFlag("tile-view.enabled", withBoolean: true)
                        $0.setFeatureFlag("toolbox.alwaysVisible", withBoolean: false)
                        $0.setFeatureFlag("toolbox.enabled", withBoolean: true)
                        $0.setFeatureFlag("video-mute.enabled", withBoolean: true)
                        $0.setFeatureFlag("video-share.enabled", withBoolean: false)
                        $0.setFeatureFlag("welcomepage.enabled", withBoolean: false)
                        $0.setFeatureFlag("help.enabled", withBoolean: false)
                        $0.setFeatureFlag("lobby-mode.enabled", withBoolean: false)
                        $0.setFeatureFlag("reactions.enabled", withBoolean: false)
                        $0.setFeatureFlag("security-options.enabled", withBoolean: true)
                        $0.setFeatureFlag("settings.profile-section.enabled", withBoolean: false)
                        $0.setFeatureFlag("settings.conference-section-only-self-view.enabled", withBoolean: true)
                        $0.setFeatureFlag("settings.links-section.enabled", withBoolean: false)
                        $0.setFeatureFlag("settings.build-info-section.enabled", withBoolean: false)
                        $0.setFeatureFlag("settings.advanced-section.enabled", withBoolean: false)
                        $0.setFeatureFlag("participants.enabled", withValue: false)
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
    
    func joinWebVideoCall(inside parentView: UIView, completion: @escaping (Error?) -> Void) {
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
                    // Make a jitsi url
                    var serverAddress: String = sessionManager.serverAddress
                    let apiPrefix = "api."
                    if serverAddress.hasPrefix(apiPrefix) {
                        let endIdx = serverAddress.index(serverAddress.startIndex, offsetBy: apiPrefix.count)
                        serverAddress.removeSubrange(serverAddress.startIndex ..< endIdx)
                    }
                    let jitsiServerAddress = "https://jitsi-www." + serverAddress

                    var jitsiURL = "\(jitsiServerAddress)/\(credentials.room)?jwt=\(credentials.token)"

                    // Append feature flags as URL parameters
                    let featureFlags: [String: Any] = [
                        "add-people.enabled": "false",
                        "audio-mute.enabled": "true",
                        "calendar.enabled": "false",
                        "call-integration.enabled": "true",
                        "car-mode.enabled": "false",
                        "close-captions.enabled": "false",
                        "conference-timer.enabled": "true",
                        "chat.enabled": "false",
                        "filmstrip.enabled": "true",
                        "fullscreen.enabled": "true",
                        "invite.enabled": "false",
                        "ios.screensharing.enabled": "false",
                        "speakerstats.enabled": "false",
                        "kick-out.enabled": "false",
                        "live-streaming.enabled": "false",
                        "meeting-name.enabled": "false",
                        "meeting-password.enabled": "false",
                        "notifications.enabled": "false",
                        "overflow-menu.enabled": "true",
                        "pip.enabled": "false",
                        "pip-while-screen-sharing.enabled": "false",
                        "prejoinpage.enabled": "true",
                        "prejoinpage.hide-display-name.enabled": "true",
                        "raise-hand.enabled": "false",
                        "recording.enabled": "false",
                        "server-url-change.enabled": "false",
                        "settings.enabled": "true",
                        "tile-view.enabled": "true",
                        "toolbox.alwaysVisible": "false",
                        "toolbox.enabled": "true",
                        "video-mute.enabled": "true",
                        "video-share.enabled": "false",
                        "welcomepage.enabled": "false",
                        "help.enabled": "false",
                        "lobby-mode.enabled": "false",
                        "reactions.enabled": "false",
                        "security-options.enabled": "true",
                        "settings.profile-section.enabled": "false",
                        "settings.conference-section-only-self-view.enabled": "true",
                        "settings.links-section.enabled": "false",
                        "settings.build-info-section.enabled": "false",
                        "settings.advanced-section.enabled": "false",
                        "participants.enabled": "false"
                    ]

                    for (key, value) in featureFlags {
                        jitsiURL += "&config.\(key)=\(value)"
                    }

                    guard let url = URL(string: jitsiURL) else {
                        completion(NinchatError(type: "unknown", props: nil))
                        return
                    }
                    
                    // Open request with jitsi url
                    let request = URLRequest(url: url)
                    openVideoCallInWebView(request: request, parentView: parentView)
                    
                    completion(nil)
                }
            }
        } catch {
            completion(error)
        }
    }

    func leaveVideoCall() {
        leaveVideoCall(force: true)
        leaveWebVideoCall()
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


// MARK: - Jitsi video calls through web view

extension NINGroupChatViewModelImpl {
    func openVideoCallInWebView(request: URLRequest, parentView: UIView) {
        // Initialize webView with configuration to allow inline media playback
        let webConfig = WKWebViewConfiguration()
        webConfig.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: webConfig)
        self.webView = webView
        
        // Set a custom non-iPhone user agent, otherwise Jitsi might not load
        self.webView?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
        
        // Set up Auto Layout constraints
        parentView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: parentView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor)
        ])

        // Set delegates
        webView.navigationDelegate = self

        // Load request
        webView.load(request)
    }
    
    func leaveWebVideoCall() {
        self.webView?.stopLoading()
        self.webView?.navigationDelegate = nil
        self.webView?.removeFromSuperview()
        self.webView = nil
    }
}

// MARK: - WKWebView delegates

extension NINGroupChatViewModelImpl: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // print("WebView error: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject JavaScript to prevent full screen and set playsinline attribute
        let preventFullscreenScript = """
        document.addEventListener('DOMContentLoaded', function() {
            var elems = document.querySelectorAll("video");
            for(var i = 0; i < elems.length; i++) {
                elems[i].setAttribute("playsinline", "true");
            }
        });
        """
        webView.evaluateJavaScript(preventFullscreenScript, completionHandler: nil)
    }
}
