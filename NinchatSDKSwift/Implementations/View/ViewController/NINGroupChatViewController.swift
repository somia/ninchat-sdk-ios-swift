//
// Copyright (c) 10.2.2023 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

// TODO: Jitsi - check landscape and iPad UI

final class NINGroupChatViewController: UIViewController, DeallocatableViewController, KeyboardHandler, HasTitleBar, HasDefaultAvatar {

    // MARK: - ViewController

    weak var delegate: NINChatSessionInternalDelegate?
    weak var sessionManager: NINChatSessionManager?

    // MARK: - Injected

    var viewModel: NINGroupChatViewModel!
    
    var onChatClosed: (() -> Void)?
    var onBackToQueue: (() -> Void)?
    var onOpenGallery: ((UIImagePickerController.SourceType) -> Void)?
    var onOpenPhotoAttachment: ((UIImage, FileInfo) -> Void)?
    var onOpenVideoAttachment: ((FileInfo) -> Void)?

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

    // MARK: - Outlets

    @IBOutlet private(set) weak var scrollableViewContainer: UIView!
    @IBOutlet private(set) weak var backgroundView: UIImageView! /// <--- to hold page background image, it is more flexible to have a dedicated view

    @IBOutlet private(set) weak var videoViewContainer: UIView!

    @IBOutlet private(set) weak var joinVideoContainerHeight: NSLayoutConstraint!
    @IBOutlet private(set) weak var joinVideoContainer: UIView! {
        didSet {
//            let currentVideoView: UIView = queue?.isGroup == true
//                ? groupVideoView
//                : videoView
//
//            videoContainer.addSubview(currentVideoView)
//            currentVideoView
//                .fix(leading: (0.0, videoContainer), trailing: (0.0, videoContainer))
//                .fix(top: (0.0, videoContainer), bottom: (0.0, videoContainer))
        }
    }

    @IBOutlet private(set) weak var joinVideoButton: JoinVideoButton!
    @IBOutlet private(set) weak var joinVideoStack: UIStackView!

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
//            if self.hasTitlebar {
//                closeChatButton.isHidden = true; return
//            }

            let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:])
            closeChatButton.buttonTitle = closeTitle
            closeChatButton.overrideAssets(with: self.delegate, in: .chatTopRight)
            closeChatButton.closure = { [weak self] button in
                DispatchQueue.main.async {
                    self?.onCloseChatTapped()
                }
            }
        }
    }

    private lazy var inputControlsView: ChatInputControlsProtocol = {
        let view: ChatInputControls = ChatInputControls.loadFromNib()
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
            inputContainer.addSubview(inputControlsView)
            inputControlsView
                .fix(leading: (0.0, inputContainer), trailing: (0.0, inputContainer))
                .fix(top: (0.0, inputContainer), bottom: (0.0, inputContainer), toSafeArea: true)
        }
    }

    // MARK: - KeyboardHandler

    var onKeyboardSizeChanged: ((CGFloat) -> Void)?

    // MARK: - HasTitleBar

    @IBOutlet private(set) weak var titlebar: UIView?
    @IBOutlet private(set) weak var titlebarContainer: UIView?

    var hasTitlebar: Bool {
        true
    }

    var titlebarAvatar: String? {
        /// - agentAvatar:true, show user_attrs.iconurl everywhere
        /// - agentAvatar:url, show that instead
        if let avatar = self.sessionManager?.siteConfiguration.agentAvatar as? Bool, avatar {
            return self.sessionManager?.agent?.iconURL
        }
        return self.sessionManager?.siteConfiguration.agentAvatar as? String
    }

    var titlebarName: String? {
        self.sessionManager?.siteConfiguration.agentName ?? self.sessionManager?.agent?.displayName
    }

    var titlebarJob: String? {
        /// `https://github.com/somia/mobile/issues/411#issuecomment-1249263156`
        if let agentName = self.sessionManager?.siteConfiguration.agentName, !agentName.isEmpty {
            return nil
        }
        return self.sessionManager?.agent?.info?.job
    }

    // MARK: - HasDefaultAvatar

    var defaultAvatar: UIImage? {
        if let avatar = self.delegate?.override(imageAsset: .ninchatAvatarTitlebar) {
            return avatar
        }
        return UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)
    }

    // MARK: - UIViewController

    override var prefersStatusBarHidden: Bool {
        // Prefer no status bar if video is active
//        webRTCClient != nil
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitleBar(parent: self.scrollableViewContainer, showAvatar: true, adjustToSafeArea: true) { [weak self] in
            DispatchQueue.main.async {
                self?.onCloseChatTapped()
            }
        }
        self.overrideAssets()
        self.addKeyboardListeners()
        self.setupView()
        self.setupViewModel()
        self.setupKeyboardClosure()
//        self.connectRTC()

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.navigationItem.setHidesBackButton(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTitlebar(showAvatar: true)
        self.addRotationListener()
        self.reloadView()
        self.adjustConstraints(for: self.view.bounds.size, withAnimation: false)
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
//        self.deallocRTC()
//        self.deallocViewModel()
        self.removeKeyboardListeners()

        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }

    // MARK: - Setup View

    private func setupView() {
        self.setupGestures()
        self.reloadView()
        self.updateInputContainerHeight(94.0)
        self.moveVideoContainerToBack()

        self.inputControlsView.onTextSizeChanged = { [weak self] height in
            debugger("new text area height: \(height + Margins.kTextFieldPaddingHeight.rawValue)")
            self?.updateInputContainerHeight(height + Margins.kTextFieldPaddingHeight.rawValue)
        }
    }

    /// In case the queue was transferred
    private func reloadView() {
//        if let queue = self.queue {
//            /// Apply queue permissions to view
//            self.inputControlsView.updatePermissions(queue.permissions)
//        }
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
                self?.chatView.didLoadHistory()
            }
        }
        self.viewModel.onComposeActionUpdated = { [weak self] id, action in
            self?.chatView.didUpdateComposeAction(id, with: action)
        }

        self.viewModel.onGroupVideoUpdated = { [weak self] event in
            switch event {
            case .readyToClose:
                self?.moveVideoContainerToBack()
            default:
                return
            }
        }

        self.viewModel.loadHistory()
    }

    // MARK: - Video Call

    @IBAction func onJoinVidoCallDidTap(_ sender: Any) {
        viewModel.joinVideoCall(inside: videoViewContainer) { [weak self] error in
            if error != nil {
                // TODO: Jitsi - localize error
                debugger("Jitsi: join video error: \(error)")
                Toast.show(message: .error("Failed to join video meeting"))
            } else {
                self?.moveVideoContainerToFront()
            }
        }
    }
}

// MARK: - Setup view

extension NINGroupChatViewController {
    private func setupGestures() {
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:))))
    }

    private func disableView(_ disable: Bool) {
        self.view.endEditing(true)
        self.inputControlsView.isUserInteractionEnabled = !disable
    }

    private func overrideAssets() {
        overrideTitlebarAssets()
//        videoView.overrideAssets()
        inputControlsView.overrideAssets()

        joinVideoButton.overrideAssets(with: delegate, isPrimary: true)

        if let backgroundImage = self.delegate?.override(imageAsset: .ninchatChatBackground) {
            self.backgroundView.backgroundColor = UIColor(patternImage: backgroundImage)
        } else if let bundleImage = UIImage(named: "chat_background_pattern", in: .SDKBundle, compatibleWith: nil) {
            self.backgroundView.backgroundColor = UIColor(patternImage: bundleImage)
        }

        self.titlebar?.reloadInputViews()
        self.titlebar?.setNeedsLayout()
        self.titlebar?.layoutIfNeeded()

//        self.videoView.reloadInputViews()
//        self.videoView.setNeedsLayout()
//        self.videoView.layoutIfNeeded()

        self.inputControlsView.reloadInputViews()
        self.inputControlsView.setNeedsLayout()
        self.inputControlsView.layoutIfNeeded()

        self.inputContainer.reloadInputViews()
        self.inputContainer.setNeedsLayout()
        self.inputContainer.layoutIfNeeded()
    }

    @objc
    private func dismissKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
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

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        self.inputControlsView.setNeedsLayout()
        self.inputControlsView.layoutIfNeeded()
    }

    /// Aligns (or cancels existing alignment) the input control container view's top
    /// to the screen bottom to hide the controls.
    private func alignInputControlsTopToScreenBottom(_ hide: Bool) {
        self.updateInputContainerHeight((hide) ? 0 : self.inputContainerHeight, update: false)
        self.inputContainer.isHidden = hide
    }

    private func adjustConstraints(for size: CGSize, withAnimation animation: Bool) {
        let hasJoinedVideo = viewModel.hasJoinedVideo

        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            /// On iPad we won't show full-screen videos as there is enough space to chat and video in parallel
            joinVideoContainerHeight.constant = hasJoinedVideo ? 0 : size.height * 0.25
            self.alignInputControlsTopToScreenBottom(false)
        } else if UIDevice.current.orientation.isLandscape {
            // In landscape we make video fullscreen ie. hide the chat view + input controls
            // If no video; get rid of the video view. the input container and video (0-height) will dictate size
            joinVideoContainerHeight.constant = hasJoinedVideo ? 0 : size.height
            self.alignInputControlsTopToScreenBottom(!hasJoinedVideo)
        } else if UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isFlat || UIDevice.current.orientation == .unknown {
            // In portrait we make the video cover about the top half of the screen
            // If no video; get rid of the video view
            joinVideoContainerHeight.constant = hasJoinedVideo ? 0 : size.height * 0.25
            self.alignInputControlsTopToScreenBottom(false)
        }

        joinVideoContainerHeight.isActive = true
        chatContainerHeight.isActive = true
        self.setNeedsStatusBarAppearanceUpdate()

        guard animation else { return }
        UIView.animate(withDuration: TimeConstants.kAnimationDuration.rawValue) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - Media

extension NINGroupChatViewController {
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
                if source == .camera {
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

extension NINGroupChatViewController {
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

            self?.moveVideoContainerToBack()
            self?.viewModel.leaveVideoCall()
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
}

// MARK: - Notifications handlers

extension NINGroupChatViewController {
    override func orientationChanged(notification: Notification) {
//        self.videoView.resizeRemoteVideo()
//        self.videoView.resizeLocalVideo()
    }

    @objc
    private func willEnterBackground(notification: Notification) {
        viewModel.willEnterBackground()
    }

    @objc
    private func didEnterForeground(notification: Notification) {
        viewModel.didEnterForeground()
    }
}

// MARK: - Helpers

extension NINGroupChatViewController {
    private func moveVideoContainerToFront() {
        view.bringSubviewToFront(videoViewContainer)
    }

    private func moveVideoContainerToBack() {
        view.sendSubviewToBack(videoViewContainer)
    }
}
