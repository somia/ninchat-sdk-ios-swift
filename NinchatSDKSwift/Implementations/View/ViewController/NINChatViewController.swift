//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINChatViewController: UIViewController, ViewController, KeyboardHandler, HasCustomLayer, HasTitleBar, HasDefaultAvatar {
    private var webRTCClient: NINChatWebRTCClient?

    // MARK: - ViewController

    weak var delegate: NINChatSessionInternalDelegate?
    weak var sessionManager: NINChatSessionManager?

    // MARK: - Injected

    var queue: Queue?
    var viewModel: NINChatViewModel!
    var chatDataSourceDelegate: NINChatDataSourceDelegate! {
        didSet {
            chatDataSourceDelegate.onCloseChatTapped = { [weak self] in
                self?.onCloseChatTapped()
            }
            chatDataSourceDelegate.onUIActionError = { _ in
                Toast.show(message: .error("failed to send message"))
            }
        }
    }
    var chatVideoDelegate: NINRTCVideoDelegate! {
        didSet {
            chatVideoDelegate.onSizeChange = { [weak self] size in
                self?.videoView.resizeRemoteVideo(to: size)
            }
        }
    }
    var chatRTCDelegate: NINWebRTCDelegate! {
        didSet {
            chatRTCDelegate.onActionError = { [weak self] error in
                self?.disconnectRTC {
                    self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
                }
            }
            
            chatRTCDelegate.onRemoteVideoTrack = { [weak self] remoteVideo, remoteVideoTrack in
                self?.videoView.remoteCapture = remoteVideo
                
                guard self?.videoView.remoteVideoTrack != remoteVideoTrack else { return }
                self?.videoView.remoteVideoTrack = remoteVideoTrack
            }
            
            chatRTCDelegate.onLocalCapture = { [weak self] localCapturer in
                self?.videoView.localCapture = localCapturer
            }
        }
    }
    var chatMediaPickerDelegate: NINPickerControllerDelegate! {
        didSet {
            chatMediaPickerDelegate.onMediaSent = { error in
                if error != nil {
                    Toast.show(message: .error("Failed to send the attachment"))
                }
            }
            chatMediaPickerDelegate.onDismissPicker = { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    var onChatClosed: (() -> Void)?
    var onBackToQueue: (() -> Void)?
    var onOpenGallery: ((UIImagePickerController.SourceType) -> Void)?
    var onOpenPhotoAttachment: ((UIImage, FileInfo) -> Void)?
    var onOpenVideoAttachment: ((FileInfo) -> Void)?
    
    // MARK: - KeyboardHandler
    
    var onKeyboardSizeChanged: ((CGFloat) -> Void)?
    var scrollableView: UIView! {
        scrollableViewContainer
    }

    // MARK: - Outlets

    @IBOutlet private(set) weak var scrollableViewContainer: UIView!
    @IBOutlet private(set) weak var backgroundView: UIImageView!     /// <--- to hold page background image, it is more flexible to have a dedicated view

    private lazy var videoView: VideoViewProtocol = {
        let view: VideoView = VideoView.loadFromNib()
        view.viewModel = viewModel
        view.delegate = delegate
        view.onCameraTapped = { [weak self] button in
            self?.onVideoCameraTapped(with: button)
        }
        view.onAudioTapped = { [weak self] button in
            self?.onVideoAudioTapped(with: button)
        }
        view.onHangupTapped = { [weak self] _ in
            self?.onVideoHangupTapped()
        }
        
        return view
    }()
    @IBOutlet private(set) weak var videoContainerHeight: NSLayoutConstraint!
    @IBOutlet private(set) weak var videoContainer: UIView! {
        didSet {
            videoContainer.addSubview(videoView)
            videoView
                .fix(leading: (0.0, videoContainer), trailing: (0.0, videoContainer))
                .fix(top: (0.0, videoContainer), bottom: (0.0, videoContainer))
        }
    }
    
    @IBOutlet private(set) weak var chatContainerHeight: NSLayoutConstraint!
    @IBOutlet private(set) weak var chatView: ChatView! {
        didSet {
            chatView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:))))
            chatView.sessionManager = self.sessionManager
            chatView.delegate = self.chatDataSourceDelegate
            chatView.dataSource = self.chatDataSourceDelegate
        }
    }
    @IBOutlet private(set) weak var closeChatButton: CloseButton! {
        didSet {
            closeChatButton.isHidden = hasTitlebar

            let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:])
            closeChatButton.buttonTitle = closeTitle
            closeChatButton.overrideAssets(with: self.delegate)
            closeChatButton.closure = { [weak self] button in
                DispatchQueue.main.async {
                    self?.onCloseChatTapped()
                }
            }
        }
    }
    
    private lazy var inputControlsView: ChatInputControlsProtocol = {
        let view: ChatInputControls = ChatInputControls.loadFromNib()
        view.viewModel = viewModel
        view.delegate = self.delegate
        view.sessionManager = self.sessionManager
        view.onSendTapped = { [weak self] text in
            self?.onSendTapped(text)
        }
        view.onAttachmentTapped = { [weak self] button in
            self?.onAttachmentTapped(with: button)
        }
        view.onWritingStatusChanged = { [weak self] isWriting in
            self?.viewModel.updateWriting(state: isWriting)
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(inputControlsContainerTapped(_:))))
        
        return view
    }()
    private var inputContainerHeight: CGFloat!
    @IBOutlet private weak var inputContainer: UIView! {
        didSet {
            inputContainerHeight = 94.5
            inputContainer.addSubview(inputControlsView)
            inputControlsView
                .fix(leading: (0.0, inputContainer), trailing: (0.0, inputContainer))
                .fix(top: (0.0, inputContainer), bottom: (0.0, inputContainer), toSafeArea: true)
        }
    }
    
    private let confirmVideoDialog: ConfirmVideoCallView = ConfirmVideoCallView.loadFromNib()

    /// MARK: - HasTitleBar

    @IBOutlet private(set) weak var titlebar: UIView?
    @IBOutlet private(set) weak var titlebarContainer: UIView?
    var titlebarAvatar: String? {
        /// - agentAvatar:true, show user_attrs.iconurl everywhere
        /// - agentAvatar:url, show that instead
        guard let avatar = self.sessionManager?.siteConfiguration.agentAvatar as? Bool else { return nil }
        return (self.sessionManager?.siteConfiguration.agentAvatar as? String) ?? (self.sessionManager?.agent?.iconURL)
    }
    var titlebarName: String? {
        self.sessionManager?.siteConfiguration.agentName ?? self.sessionManager?.agent?.displayName
    }
    var titlebarJob: String? {
        self.sessionManager?.agent?.info?.job
    }

    // MARK: - HasTitleBar

    private(set) var defaultAvatar: UIImage? = UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)

    // MARK: - UIViewController
    
    override var prefersStatusBarHidden: Bool {
        // Prefer no status bar if video is active
        webRTCClient != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitleBar(parent: self.scrollableViewContainer, adjustToSafeArea: true) { [weak self] in
            DispatchQueue.main.async {
                self?.onCloseChatTapped()
            }
        }
        self.addKeyboardListeners()
        self.setupView()
        self.setupViewModel()
        self.setupKeyboardClosure()
        self.connectRTC()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addRotationListener()
        self.reloadView()
        self.adjustConstraints(for: self.view.bounds.size, withAnimation: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let titlebarContainer = self.titlebarContainer {
            applyLayerOverride(view: titlebarContainer)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeRotationListener()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.adjustConstraints(for: size, withAnimation: true)
        self.view.endEditing(true)
    }
    
    deinit {
        self.deallocate()
    }

    func deallocate() {
        self.deallocRTC()
        self.deallocViewModel()
        self.removeKeyboardListeners()

        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }

    // MARK: - Setup View
    
    private func setupView() {
        self.overrideAssets()
        self.setupGestures()
        self.reloadView()

        self.inputControlsView.onTextSizeChanged = { [weak self] height in
            debugger("new text area height: \(height + Margins.kTextFieldPaddingHeight.rawValue)")
            self?.updateInputContainerHeight(height + Margins.kTextFieldPaddingHeight.rawValue)
        }
    }

    /// In case the queue was transferred
    private func reloadView() {
        if let queue = self.queue {
            /// Apply queue permissions to view
            self.inputControlsView.updatePermissions(queue.permissions)
        }
        self.disableView(false)
        self.chatView.tableView.reloadData()
    }

    // MARK: - Setup ViewModel
    
    private func setupViewModel() {
        self.viewModel.onErrorOccurred = { error in
            if let error = error as? AttachmentError {
                Toast.show(message: .error(error.localizedDescription))
            }
        }
        self.viewModel.onChannelClosed = { [weak self] in
            self?.disableView(true)
        }
        self.viewModel.onQueueUpdated = { [weak self] in
            self?.disableView(true)
            self?.onBackToQueue?()
        }
        self.viewModel.onChannelMessage = { [weak self] update in
            switch update {
            case .insert(let index):
                self?.chatView.didAddMessage(at: index)
            case .remove(let index):
                self?.chatView.didRemoveMessage(from: index)
            case .history, .clean:
                self?.chatView.tableView.reloadData()
            }
        }
        self.viewModel.loadHistory { _ in }
        self.viewModel.onComposeActionUpdated = { [weak self] id, action in
            self?.chatView.didUpdateComposeAction(id, with: action)
        }
    }
    
    // MARK: - Helpers
    
    private func connectRTC() {
        func permissionError(_ error: Error?, callPickedUp: Bool = true) -> Bool {
            if error as? PermissionError != nil {
                /// 1. Show toast to notify the user
                Toast.show(message: .error("\("Permission denied".localized)\n\("Update Settings".localized)"))
                /// 2. Cancel the call
                self.viewModel.pickup(answer: false, unsupported: true) { _ in  }
                /// 3. Discard the process
                return true
            }
            return false
        }

        /// send .answer response
        func answerCall(with action: ConfirmAction) {
            debugger("accept call: \(action == .confirm)")

            switch action {
            case .cancel:
                self.viewModel.pickup(answer: false) { error in
                    if error != nil { Toast.show(message: .error("WebRTC pickup fail".localized)) }
                }
            case .confirm:
                debugger("WebRTC: Grant permission for the video call")
                self.viewModel.grantVideoCallPermissions { error in
                    if permissionError(error) { return }

                    debugger("WebRTC: Permissions granted - initializing the video call (answer)")
                    self.viewModel.pickup(answer: true) { error in
                        if error != nil { Toast.show(message: .error("WebRTC pickup fail".localized)) }
                    }
                }
            }
        }

        self.viewModel.listenToRTCSignaling(delegate: chatRTCDelegate, onCallReceived: { [weak self] channel, error in
            /// accept invite silently when re-invited `https://github.com/somia/mobile/issues/232`
            guard self?.webRTCClient == nil else {
                debugger("WebRTC: Silently accept the video call")
                answerCall(with: .confirm); return
            }
            DispatchQueue.main.async {
                self?.view.endEditing(true)

                self?.confirmVideoDialog.user = channel
                self?.confirmVideoDialog.delegate = self?.delegate
                self?.confirmVideoDialog.sessionManager = self?.sessionManager
                self?.confirmVideoDialog.onViewAction = { action in
                    self?.confirmVideoDialog.hideConfirmView()
                    answerCall(with: action)
                }
                self?.confirmVideoDialog.showConfirmView(on: self?.view ?? UIView())
            }
            
        }, onCallInitiated: { [weak self] rtcClient, error in
            self?.webRTCClient = rtcClient
            DispatchQueue.main.async {
                self?.closeChatButton.hide = true
                self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)

                self?.videoView.isSelected = false
                self?.videoView.resizeLocalVideo()
                self?.disableIdleTimer(true)
            }
        }, onCallHangup: { [weak self] in
            DispatchQueue.main.async {
                self?.disableIdleTimer(false)
                self?.confirmVideoDialog.hideConfirmView()
                
                self?.disconnectRTC {
                    self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
                }
            }
        })
    }
    
    private func disconnectRTC(completion: (() -> Void)? = nil) {
        self.viewModel.disconnectRTC(self.webRTCClient) { [weak self] in
            DispatchQueue.main.async {
                self?.closeChatButton.hide = false
                self?.videoView.localCapture = nil
                self?.videoView.remoteVideoTrack = nil
                self?.webRTCClient = nil
                completion?()
            }
        }
    }
    
    /// The function is aimed to disconnect the RTC client on deallocation of the View Controller
    /// Capturing `[weak self]` while deallocation results in a crash
    private func deallocRTC() {
        self.viewModel.disconnectRTC(self.webRTCClient, completion: nil)
    }

    private func deallocViewModel() {
        debugger("** ** deallocate view model")

        self.viewModel.onChannelClosed = nil
        self.viewModel.onQueueUpdated = nil
        self.viewModel.onChannelMessage = nil
    }
}

// MARK: - Setup view

extension NINChatViewController {
    private func setupGestures() {
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:))))
    }
    
    private func disableView(_ disable: Bool) {
        self.view.endEditing(true)
        self.inputControlsView.isUserInteractionEnabled = !disable
    }
    
    private func overrideAssets() {
        overrideTitlebarAssets()
        videoView.overrideAssets()
        inputControlsView.overrideAssets()

        if let backgroundImage = self.delegate?.override(imageAsset: .ninchatChatBackground) {
            self.backgroundView.backgroundColor = UIColor(patternImage: backgroundImage)
        } else if let bundleImage = UIImage(named: "chat_background_pattern", in: .SDKBundle, compatibleWith: nil) {
            self.backgroundView.backgroundColor = UIColor(patternImage: bundleImage)
        }
    }
    
    func setupKeyboardClosure() {
        self.onKeyboardSizeChanged = { [weak self] height in
            self?.chatView.updateContentSize(height)
        }
    }
    
    private func updateInputContainerHeight(_ value: CGFloat, update: Bool = true) {
        self.inputContainer.height?.constant = value
        if update {
            self.inputContainerHeight = value
        }
    
        self.view.layoutIfNeeded()
    }
    
    /// Aligns (or cancels existing alignment) the input control container view's top
    /// to the screen bottom to hide the controls.
    private func alignInputControlsTopToScreenBottom(_ hide: Bool) {
        self.updateInputContainerHeight((hide) ? 0 : self.inputContainerHeight, update: false)
        self.inputContainer.isHidden = hide
    }
    
    private func adjustConstraints(for size: CGSize, withAnimation animation: Bool) {
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            /// On iPad we won't show full-screen videos as there is enough space to chat and video in parallel
            videoContainerHeight.constant = (self.webRTCClient != nil) ? size.height * 0.45 : 0
            self.alignInputControlsTopToScreenBottom(false)
        } else if UIDevice.current.orientation.isLandscape {
            // In landscape we make video fullscreen ie. hide the chat view + input controls
            // If no video; get rid of the video view. the input container and video (0-height) will dictate size
            videoContainerHeight.constant = (self.webRTCClient != nil) ? size.height : 0
            self.alignInputControlsTopToScreenBottom(self.webRTCClient != nil)
        } else if UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isFlat {
            // In portrait we make the video cover about the top half of the screen
            // If no video; get rid of the video view
            videoContainerHeight.constant = (self.webRTCClient != nil) ? size.height * 0.45 : 0
            self.alignInputControlsTopToScreenBottom(false)
        }

        videoContainerHeight.isActive = true
        chatContainerHeight.isActive = true
        self.setNeedsStatusBarAppearanceUpdate()
        
        guard animation else { return }
        UIView.animate(withDuration: TimeConstants.kAnimationDuration.rawValue) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    @objc
    private func dismissKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}

// MARK: - Media

extension NINChatViewController {
    private func onAttachmentTapped(with button: UIButton) {
        ChoiceDialogue.showDialogue(withOptions: ["Camera".localized, "Photo Library".localized]) { [weak self] result in
            switch result {
            case .cancel:
                break
            case .select(let index):
                let source: UIImagePickerController.SourceType = (index == 0) ? .camera : .photoLibrary
                guard UIImagePickerController.isSourceTypeAvailable(source) else {
                    Toast.show(message: .error("Source not available".localized)); return
                }
                if source == .camera && self?.webRTCClient != nil {
                    Toast.show(message: .error("Camera not available".localized)); return
                }

                self?.viewModel.openAttachment(source: source) { [weak self, source] error in
                    if error == nil {
                        self?.onOpenGallery?(source); return
                    }
                    Toast.show(message: .error("\("Access denied".localized)\n\("Update Settings".localized)"))
                }
            }
        }
    }
}

// MARK: - User actions

extension NINChatViewController {
    @objc
    private func inputControlsContainerTapped(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        inputControlsView.isSelected = true
    }
    
    private func onCloseChatTapped() {
        debugger("Close chat button pressed!")
        
        let confirmCloseDialog: ConfirmCloseChatView = ConfirmCloseChatView.loadFromNib()
        confirmCloseDialog.delegate = self.delegate
        confirmCloseDialog.sessionManager = self.sessionManager
        confirmCloseDialog.onViewAction = { [weak self] action in
            confirmCloseDialog.hideConfirmView()
            guard action == .confirm else { return }
            
            self?.disconnectRTC()
            self?.onChatClosed?()
        }
        confirmCloseDialog.showConfirmView(on: self.view)
    }
    
    // MARK: - Message
    
    private func onSendTapped(_ text: String) {
        self.viewModel.send(message: text) { error in
            if error != nil { Toast.show(message: .error("Failed to send message")) }
        }
    }
    
    // MARK: - Video
    
    private func onVideoCameraTapped(with button: UIButton) {
        self.webRTCClient?.disableLocalVideo = !button.isSelected
        self.delegate?.log(value: "Video disabled: \(!button.isSelected)")
        
        button.isSelected = !button.isSelected
    }
    
    private func onVideoAudioTapped(with button: UIButton) {
        self.webRTCClient?.disableLocalAudio = !button.isSelected
        self.delegate?.log(value: "Audio disabled: \(!button.isSelected)")
        
        button.isSelected = !button.isSelected
    }
    
    private func onVideoHangupTapped() {
        self.delegate?.log(value: "Hang-up button pressed")
        self.viewModel?.send(type: .hangup, payload: [:]) { [weak self] error in
            self?.disconnectRTC {
                self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
            }
        }
    }
}

// MARK: - Notifications handlers

extension NINChatViewController {    
    override func orientationChanged(notification: Notification) {
        self.videoView.resizeRemoteVideo()
        self.videoView.resizeLocalVideo()
    }
    
    @objc
    private func didEnterBackground(notification: Notification) {
        viewModel.appDidEnterBackground { [weak self] error in
            if let error = error {
                debugger("failed to send hang-up: \(error)")
            }
            
            self?.view.endEditing(true)
            self?.disconnectRTC {
                self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
            }
        }
    }

    @objc
    private func willResignActive(notification: Notification) {
        /// For the time-being, the solo solution is to terminate the call and then re-initiate it from the agent.
        /// I may pause/resume the video later, when I figure out how to.
        self.didEnterBackground(notification: notification)
//        viewModel.appWillResignActive { _ in }
    }
}

// MARK: - Helpers

extension NINChatViewController {
    private func disableIdleTimer(_ disable: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disable
    }
}
