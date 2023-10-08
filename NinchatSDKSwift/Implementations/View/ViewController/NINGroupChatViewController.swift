//
// Copyright (c) 10.2.2023 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

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
    var isWebVideoCall = false

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
    @IBOutlet private(set) weak var webVideoViewContainer: UIView!

    @IBOutlet private(set) weak var joinVideoContainerHeight: NSLayoutConstraint!
    @IBOutlet private(set) weak var joinVideoContainer: UIView!

    @IBOutlet private(set) weak var joinVideoTitleLabel: UILabel!
    @IBOutlet private(set) weak var joinVideoButton: JoinVideoButton!
    @IBOutlet private(set) weak var joinVideoIcon: UIImageView!
    @IBOutlet private(set) weak var joinVideoInfoLabel: UILabel!
    @IBOutlet private(set) weak var joinVideoStack: UIStackView!
    @IBOutlet private(set) weak var joinVideoScrollView: UIScrollView!

    @IBOutlet private(set) weak var chatContainer: UIView!
    @IBOutlet private(set) weak var chatContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private(set) weak var chatContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private(set) weak var chatView: ChatView! {
        didSet {
            chatView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:))))
            chatView.sessionManager = self.sessionManager
            chatView.delegate = self.chatDataSourceDelegate
            chatView.dataSource = self.chatDataSourceDelegate
        }
    }

    @IBOutlet private(set) weak var chatControlsContainer: UIStackView!
    @IBOutlet private(set) weak var toggleChatButton: NINButton! {
        didSet {
            markChatButton(hasUnreadMessages: false)
        }
    }
    @IBOutlet private(set) weak var closeChatButton: CloseButton! {
        didSet {
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
    private var isChatShownDuringVideo = false
    private var hasClosedChannel = false

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
    var scrollableView: UIView! {
        scrollableViewContainer
    }

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
        /// Group-chat related logic - we hide job name if title bar is hidden in site configs
        guard sessionManager?.siteConfiguration.hideTitlebar == false else {
            return nil
        }
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
        viewModel.hasJoinedVideo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitleBar(parent: self.chatContainer, showAvatar: true, collapseCloseButton: true, adjustToSafeArea: true) { [weak self] in
            DispatchQueue.main.async {
                self?.onCloseChatTapped()
            }
        }
        self.overrideAssets()
        self.addKeyboardListeners()
        self.setupView()
        self.setupViewModel()
        self.setupKeyboardClosure()

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterBackground(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.navigationItem.setHidesBackButton(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTitlebar(showAvatar: true, collapseCloseButton: true)
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
        self.deallocViewModel()
        self.removeKeyboardListeners()

        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }

    // MARK: - Setup View

    private func setupView() {
        self.setupGestures()
        self.reloadView()
        self.updateInputContainerHeight(94.0)
        
        self.moveVideoContainerToBack()
        self.moveWebVideoContainerToBack()
        
        self.toggleChatButton.isHidden = true
        self.chatContainerTopConstraint.constant = joinVideoContainerHeight.constant

        joinVideoButton.setTitle(self.sessionManager?.translate(key: Constants.kJoinVideoMeetingText.rawValue, formatParams: [:]), for: .normal)
        joinVideoTitleLabel.text = self.sessionManager?.translate(key: Constants.kVideoMeetingText.rawValue, formatParams: [:])
        joinVideoInfoLabel.text = self.sessionManager?.siteConfiguration.videoMeetingInfoText

        self.inputControlsView.onTextSizeChanged = { [weak self] height in
            debugger("new text area height: \(height + Margins.kTextFieldPaddingHeight.rawValue)")
            self?.updateInputContainerHeight(height + Margins.kTextFieldPaddingHeight.rawValue)
        }
    }

    /// In case the queue was transferred
    private func reloadView() {
//        if let queue = self.viewModel.queue {
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
            self?.hasClosedChannel = true

            self?.joinVideoContainerHeight.constant = 0
            self?.viewModel.leaveVideoCall()
            self?.markVideoCallAsFinished()
            self?.disableView(true)
        }
        self.viewModel.onQueueUpdated = { [weak self] in
            self?.disableView(true)
            self?.onBackToQueue?()
        }
        self.viewModel.onChannelMessage = { [weak self] update in
            guard let self = self else {
                return
            }
            switch update {
            case .insert(let index):
                self.chatView.didAddMessage(at: index)
            case .update(let index):
                self.chatView.didUpdateMessage(at: index)
            case .remove(let index):
                self.chatView.didRemoveMessage(from: index)
            case .history, .clean:
                self.chatView.didLoadHistory()
            }

            switch update {
            case .insert(let index), .update(let index):
                let canMarkChatButtonUnread = self.viewModel.hasJoinedVideo == true
                    && self.isChatShownDuringVideo == false

                if self.chatDataSourceDelegate.message(at: index, self.chatView) is TextMessage {
                    self.markChatButton(hasUnreadMessages: canMarkChatButtonUnread)
                }
            default:
                break
            }
        }
        self.viewModel.onComposeActionUpdated = { [weak self] id, action in
            self?.chatView.didUpdateComposeAction(id, with: action)
        }
        self.viewModel.onGroupVideoReadyToClose = { [weak self] in
            self?.moveVideoContainerToBack()
            self?.moveWebVideoContainerToBack()
            
            self?.markChatButton(hasUnreadMessages: false)
            self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: false)
            self?.toggleChatButton.isHidden = true
            self?.isChatShownDuringVideo = false
            self?.chatContainerTopConstraint.constant = self?.joinVideoContainerHeight.constant ?? .zero
            self?.chatContainer.layer.removeAllAnimations()
            self?.chatContainer.transform = .identity
        }

        self.viewModel.loadHistory()
    }

    // MARK: - Video Call

    @IBAction func onJoinVideoCallDidTap(_ sender: Any) {
        isWebVideoCall = false
        view.endEditing(true)
        viewModel.joinVideoCall(inside: videoViewContainer) { [weak self] error in
            if error != nil {
                // TODO: Jitsi - localize error
                debugger("Jitsi: join video error: \(error)")
                Toast.show(message: .error("Failed to join video meeting"))
            } else {
                self?.moveVideoContainerToFront()
                self?.toggleChatButton.isHidden = false
            }
        }
    }
    
    @IBAction func onJoinWebVideoWithURLCallDidTap(_ sender: Any) {
        isWebVideoCall = true
        view.endEditing(true)
        viewModel.joinWebVideoCallWithUrl(inside: webVideoViewContainer) { [weak self] error in
            if error != nil {
                // TODO: Jitsi - localize error
                debugger("Jitsi: join video error: \(error)")
                Toast.show(message: .error("Failed to join video meeting"))
            } else {
                self?.moveWebVideoContainerToFront()
                self?.toggleChatButton.isHidden = false
            }
        }
    }
    
    @IBAction func onJoinWebVideoWithIframeCallDidTap(_ sender: Any) {
        isWebVideoCall = true
        view.endEditing(true)
        viewModel.joinWebVideoCallWithIframe(inside: webVideoViewContainer) { [weak self] error in
            if error != nil {
                // TODO: Jitsi - localize error
                debugger("Jitsi: join video error: \(error)")
                Toast.show(message: .error("Failed to join video meeting"))
            } else {
                self?.moveWebVideoContainerToFront()
                self?.toggleChatButton.isHidden = false
            }
        }
    }
    
    @IBAction func onNinchatNewUrlDidTap(_ sender: Any) {
        isWebVideoCall = true
        view.endEditing(true)
        viewModel.openNinchatNewUrl(inside: webVideoViewContainer) { [weak self] error in
            if error != nil {
                // TODO: Jitsi - localize error
                debugger("Jitsi: join video error: \(error)")
                Toast.show(message: .error("Failed to join video meeting"))
            } else {
                self?.moveWebVideoContainerToFront()
                self?.toggleChatButton.isHidden = false
            }
        }
    }

    @IBAction func onToggleChatDidTap(_ sender: Any) {
        chatContainer.layer.removeAllAnimations()
        let (desiredTopConstraint, desiredLeadingConstraint) = desiredChatConstraints(for: view.bounds.size)
        if chatContainerTopConstraint.constant != desiredTopConstraint || chatContainerLeadingConstraint.constant != desiredLeadingConstraint {
            chatContainerTopConstraint.constant = desiredTopConstraint
            chatContainerLeadingConstraint.constant = desiredLeadingConstraint
            view.layoutSubviews()
        }
        let transformHeight = chatContainer.bounds.height

        if isChatShownDuringVideo {
            view.endEditing(true)
            UIView.animate(
                withDuration: TimeConstants.kAnimationDuration.rawValue,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState],
                animations: {
                    self.chatContainer.transform = CGAffineTransform(translationX: 0, y: transformHeight)
                }, completion: { _ in
                    if self.viewModel.hasJoinedVideo && !self.isChatShownDuringVideo {
                        self.moveVideoContainerToFront()
                        self.moveWebVideoContainerToFront()
                    }
                }
            )
        } else {
            chatContainer.transform = CGAffineTransform(translationX: 0, y: transformHeight)
            moveChatToFront()
            UIView.animate(
                withDuration: TimeConstants.kAnimationDuration.rawValue,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction, .beginFromCurrentState],
                animations: {
                    self.chatContainer.transform = .identity
                }, completion: { _ in
                    self.markChatButton(hasUnreadMessages: false)
                }
            )
        }
        isChatShownDuringVideo = !isChatShownDuringVideo
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
        inputControlsView.overrideAssets()

        joinVideoButton.overrideAssets(with: delegate, isPrimary: true)
        if let joinVideoIcon = delegate?.override(imageAsset: .ninchatGroupJoinVideoIcon) {
            self.joinVideoIcon.image = joinVideoIcon
        }

        if let backgroundImage = self.delegate?.override(imageAsset: .ninchatChatBackground) {
            self.backgroundView.backgroundColor = UIColor(patternImage: backgroundImage)
        } else if let bundleImage = UIImage(named: "chat_background_pattern", in: .SDKBundle, compatibleWith: nil) {
            self.backgroundView.backgroundColor = UIColor(patternImage: bundleImage)
        }

        if let toggleChatIcon = delegate?.override(imageAsset: .ninchatGroupChatToggleIcon) {
            toggleChatButton.setImage(toggleChatIcon, for: .normal)
        }

        self.titlebar?.reloadInputViews()
        self.titlebar?.setNeedsLayout()
        self.titlebar?.layoutIfNeeded()

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
        let shouldShowJoinVideo = !viewModel.hasJoinedVideo && !hasClosedChannel
        if shouldShowJoinVideo {
            if UIDevice.current.orientation.isLandscape {
                joinVideoContainerHeight.constant = size.height * 0.2
            } else {
                joinVideoContainerHeight.constant = self.sessionManager?.siteConfiguration.videoMeetingInfoText == nil
                    ? 155
                    : 180
            }
        } else {
            joinVideoContainerHeight.constant = 0
        }

        alignInputControlsTopToScreenBottom(false)

        if viewModel.hasJoinedVideo {
            let (desiredTopConstraint, desiredLeadingConstraint) = desiredChatConstraints(for: size)
            chatContainerTopConstraint.constant = desiredTopConstraint
            chatContainerLeadingConstraint.constant = desiredLeadingConstraint
        } else if hasClosedChannel {
            chatContainerTopConstraint.constant = 0
            chatContainerLeadingConstraint.constant = 0
        } else {
            chatContainerTopConstraint.constant = joinVideoContainerHeight.constant
            chatContainerLeadingConstraint.constant = 0
        }

        joinVideoContainerHeight.isActive = true
        self.setNeedsStatusBarAppearanceUpdate()

        guard animation else { return }
        UIView.animate(withDuration: TimeConstants.kAnimationDuration.rawValue) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    private func markVideoCallAsFinished() {
        moveVideoContainerToBack()
        moveWebVideoContainerToBack()
        
        markChatButton(hasUnreadMessages: false)
        adjustConstraints(for: view.bounds.size, withAnimation: false)
        toggleChatButton.isHidden = true
        isChatShownDuringVideo = false
        chatContainerTopConstraint.constant = joinVideoContainerHeight.constant
        chatContainer.layer.removeAllAnimations()
        chatContainer.transform = .identity
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
            self?.moveWebVideoContainerToBack()
            
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
        if UIDevice.current.orientation.isLandscape && UIScreen.main.traitCollection.userInterfaceIdiom != .pad {
            // scrolling to 'join video' button when device is rotated into landscape mode on small devices
            let yPosition = joinVideoScrollView.convert(joinVideoButton.frame, from: joinVideoStack).origin.y
            let padding: CGFloat = 16
            joinVideoScrollView.contentOffset = CGPoint(x: 0, y: yPosition - padding)
        } else {
            joinVideoScrollView.contentOffset = CGPoint(x: 0, y: 0)
        }
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
    
    private func moveWebVideoContainerToFront() {
        if isWebVideoCall {
            view.bringSubviewToFront(webVideoViewContainer)
        }
    }

    private func moveWebVideoContainerToBack() {
        view.sendSubviewToBack(webVideoViewContainer)
    }

    private func moveChatToFront() {
        view.bringSubviewToFront(chatContainer)
        titlebarContainer.map(view.bringSubviewToFront)
        titlebar.map(view.bringSubviewToFront)
        view.bringSubviewToFront(chatControlsContainer)
    }

    private func markChatButton(hasUnreadMessages: Bool) {
        // overrideAssets overrides layer of the button, and usually it can have zero size,
        // which affects button's layout (it becomes hidden), hence we're saving original frame to keep it after overrideAssets.
        let originalFrame = toggleChatButton.frame
        if hasUnreadMessages {
            toggleChatButton.tintColor = delegate?.override(colorAsset: .ninchatColorButtonPrimaryText) ?? .white
            toggleChatButton.overrideAssets(with: delegate, isPrimary: true)
        } else {
            toggleChatButton.tintColor = delegate?.override(colorAsset: .ninchatColorButtonSecondaryText) ?? .defaultBackgroundButton
            toggleChatButton.overrideAssets(with: delegate, isPrimary: false)
        }
        toggleChatButton.frame = originalFrame
    }

    private func desiredChatConstraints(for size: CGSize) -> (top: CGFloat, leading: CGFloat) {
        let desiredTopConstraint: CGFloat = UIDevice.current.orientation.isLandscape
            ? 0
            : 65
        let desiredPadLeadingConstraint: CGFloat = UIDevice.current.orientation.isLandscape
            ? size.width * (2/3)
            : 0
        let desiredLeadingConstraint = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
            ? desiredPadLeadingConstraint
            : 0
        return (desiredTopConstraint, desiredLeadingConstraint)
    }

    private func deallocViewModel() {
        debugger("** ** deallocate view model")

        self.viewModel.onChannelClosed = nil
        self.viewModel.onQueueUpdated = nil
        self.viewModel.onChannelMessage = nil
    }
}
