//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

final class NINChatViewController: UIViewController, ViewController {
    
    private let animationDuration: Double = 0.3
    private var webRTCClient: NINChatWebRTCClient?
    
    // MARK: - Injected
    
    var viewModel: NINChatViewModel!    
    var session: NINChatSessionSwift!
    var chatDataSourceDelegate: NINChatDataSourceDelegate! {
        didSet {
            chatDataSourceDelegate.onCloseChatTapped = { [weak self] in
                self?.onCloseChatTapped()
            }
            chatDataSourceDelegate.onUIActionError = { _ in
                NINToast.showWithErrorMessage("failed to send message", callback: nil)
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
            
            chatRTCDelegate.onLocalCapturer = { [weak self] localCapturer in
                self?.videoView.localCapture = localCapturer
            }
        }
    }
    var chatMediaPickerDelegate: NINPickerControllerDelegate! {
        didSet {
            chatMediaPickerDelegate.onMediaSent = { error in
                if error != nil {
                    NINToast.showWithErrorMessage("Failed to send the attachment", callback: nil)
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
    var onOpenPhotoAttachment: ((UIImage, NINFileInfo) -> Void)?
    var onOpenVideoAttachment: ((NINFileInfo) -> Void)?
    
    // MARK: - Outlets
    
    private lazy var videoView: VideoViewProtocol = {
        let view: VideoView = VideoView.loadFromNib()
        view.viewModel = viewModel
        view.session = session
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
            chatView.sessionManager = self.session.sessionManager
            chatView.delegate = self.chatDataSourceDelegate
            chatView.dataSource = self.chatDataSourceDelegate
        }
    }
    @IBOutlet private(set) weak var closeChatButton: CloseButton! {
        didSet {
            let closeTitle = self.session.sessionManager.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:])
            closeChatButton.buttonTitle = closeTitle
            closeChatButton.overrideAssets(with: self.session)
            closeChatButton.closure = { [weak self] button in
                self?.onCloseChatTapped()
            }
        }
    }
    
    private lazy var inputControlsView: ChatInputControlsProtocol = {
        let view: ChatInputControls = ChatInputControls.loadFromNib()
        view.viewModel = viewModel
        view.session = session
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
                .fix(top: (0.0, inputContainer), bottom: (0.0, inputContainer))
        }
    }
    
    // MARK: - UIViewController
    
    override var prefersStatusBarHidden: Bool {
        // Prefer no status bar if video is active
        webRTCClient != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.setupViewModel()
        self.connectRTC()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(notification:)),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive(notification:)),
                                               name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addKeyboardListeners()
        self.addRotationListener()
        self.adjustConstraints(for: self.view.bounds.size, withAnimation: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeKeyboardListeners()
        self.removeRotationListener()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.endEditing(true)
        self.adjustConstraints(for: size, withAnimation: true)
    }
    
    deinit {
        self.deallocRTC()
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    // MARK: - Setup View
    
    private func setupView() {
        self.overrideAssets()
        self.setupGestures()
        
        self.inputControlsView.onTextSizeChanged = { [weak self] height in
            debugger("new text area height: \(height + 64)")
            self?.updateInputContainerHeight(height + 64.0)
        }
    }
    
    // MARK: - Setup ViewModel
    
    private func setupViewModel() {
        self.viewModel.onChannelClosed = { [weak self] in
            self?.disableView()
        }
        self.viewModel.onQueueUpdated = { [weak self] in
            self?.disableView()
            self?.onBackToQueue?()
        }
        self.viewModel.onChannelMessage = { [weak self] update in
            switch update {
            case .insert(let index):
                self?.chatView.didAddMessage(at: index)
            case .remove(let index):
                self?.chatView.didRemoveMessage(from: index)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func connectRTC() {
        self.viewModel.listenToRTCSignaling(delegate: chatRTCDelegate, onCallReceived: { [unowned self] channel in
            self.view.endEditing(true)
            
            let confirmVideoDialog: ConfirmVideoCallView = ConfirmVideoCallView.loadFromNib()
            confirmVideoDialog.user = channel
            confirmVideoDialog.session = self.session
            confirmVideoDialog.onViewAction = { [weak self] action in
                confirmVideoDialog.hideConfirmView()
                self?.viewModel.pickup(answer: action == .confirm) { error in
                    if error != nil { NINToast.showWithErrorMessage("failed to send WebRTC pickup message", callback: nil) }
                }
            }
            confirmVideoDialog.showConfirmView(on: self.view)

        }, onCallInitiated: { [weak self] error, rtcClinet in
            self?.webRTCClient = rtcClinet
            self?.closeChatButton.hide = true
            self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
            
            self?.videoView.isSelected = false
            self?.videoView.resizeLocalVideo()
        }, onCallHangup: { [weak self] in
            self?.disconnectRTC {
                self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
            }
        })
    }
    
    private func disconnectRTC(completion: (() -> Void)? = nil) {
        self.viewModel.disconnectRTC(self.webRTCClient) { [weak self] in
            self?.closeChatButton.hide = false
            self?.videoView.localCapture = nil
            self?.videoView.remoteVideoTrack = nil
            self?.webRTCClient = nil
            completion?()
        }
    }
    
    /// The function is aimed to disconnect the RTC client on deallocation of the View Controller
    /// Capturing `[weak self]` while deallocation results in a crash
    private func deallocRTC() {
        self.viewModel.disconnectRTC(self.webRTCClient, completion: nil)
    }
}

// MARK: - Setup view

extension NINChatViewController {
    private func setupGestures() {
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:))))
    }
    
    private func disableView() {
        self.view.endEditing(true)
        self.inputControlsView.isUserInteractionEnabled = false
        self.videoView.isUserInteractionEnabled = false
    }
    
    private func overrideAssets() {
        videoView.overrideAssets()
        inputControlsView.overrideAssets()
        
        if let backgroundImage = self.session.override(imageAsset: .chatBackground) {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else if let bundleImage = UIImage(named: "chat_background_pattern", in: .SDKBundle, compatibleWith: nil) {
            self.view.backgroundColor = UIColor(patternImage: bundleImage)
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
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            // In landscape we make video fullscreen ie. hide the chat view + input controls
            // If no video; get rid of the video view. the input container and video (0-height) will dictate size
            videoContainerHeight.constant = (self.webRTCClient != nil) ? size.height : 0
            self.alignInputControlsTopToScreenBottom(self.webRTCClient != nil)
        case .portrait, .portraitUpsideDown, .faceUp, .faceDown:
            // In portrait we make the video cover about the top half of the screen
            // If no video; get rid of the video view
            videoContainerHeight.constant = (self.webRTCClient != nil) ? size.height * 0.45 : 0
            self.alignInputControlsTopToScreenBottom(false)
        default:
            break
        }
        videoContainerHeight.isActive = true
        chatContainerHeight.isActive = true
        self.setNeedsStatusBarAppearanceUpdate()
        
        guard animation else { return }
        UIView.animate(withDuration: animationDuration) {
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
    private func openGallery() {
        checkPhotoLibraryPermission { [unowned self] error in
            if let _ = error {
                NINToast.showWithErrorMessage("Photo Library access is denied.", touchedCallback: {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }, callback: nil)
            } else {
                self.onOpenGallery?(.photoLibrary)
            }
        }
    }
    
    private func openVideo() {
        checkVideoPermission { [unowned self] error in
            if let _ = error {
                NINToast.showWithErrorMessage("Camera access is denied", touchedCallback: {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }, callback: nil)
            } else {
                self.onOpenGallery?(.camera)
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
        confirmCloseDialog.session = self.session
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
            if error != nil { NINToast.showWithErrorMessage("failed to send message", callback: nil) }
        }
    }
    
    private func onAttachmentTapped(with button: UIButton) {
        guard let bundle = Bundle.SDKBundle else {
            fatalError("Error in getting SDK Bundle")
        }
        let camera = NSLocalizedString("Camera", tableName: "Localizable", bundle: bundle, value: "", comment: "")
        let photo = NSLocalizedString("Photo", tableName: "Localizable", bundle: bundle, value: "", comment: "")
        NINChoiceDialog.show(withOptionTitles: [camera, photo]) { [weak self] canceled, index in
            guard !canceled else { return }
        
            let source: UIImagePickerController.SourceType = (index == 0) ? .camera : .photoLibrary
            guard UIImagePickerController.isSourceTypeAvailable(source) else {
                NINToast.showWithErrorMessage("That source type is not available on this device", callback: nil)
                return
            }
            
            switch source {
            case .camera:
                self?.openVideo()
            case .photoLibrary:
                self?.openGallery()
            default:
                fatalError("Invalid attachment type")
            }
        }
    }
    
    // MARK: - Video
    
    private func onVideoCameraTapped(with button: UIButton) {
        self.webRTCClient?.disableLocalVideo = button.isSelected
        self.session.log(value: "Video disabled: \(button.isSelected)")
        
        button.isSelected = !button.isSelected
    }
    
    private func onVideoAudioTapped(with button: UIButton) {
        self.webRTCClient?.disableLocalAudio = button.isSelected
        self.session.log(value: "Audio disabled: \(button.isSelected)")
        
        button.isSelected = !button.isSelected
    }
    
    private func onVideoHangupTapped() {
        self.session.log(value: "Hang-up button pressed")
        self.viewModel?.send(type: .hangup, payload: [:]) { [unowned self] error in
            self.disconnectRTC {
                self.adjustConstraints(for: self.view.bounds.size, withAnimation: true)
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
        debugger("applicationWillResignActive: no action.")
        
        /// TODO: pause video - if one should be active - here?
        viewModel.appWillResignActive { _ in }
    }
}
