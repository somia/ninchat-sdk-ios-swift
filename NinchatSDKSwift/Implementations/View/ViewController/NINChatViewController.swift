//
//  NINChatViewController.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 9.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit
import NinchatSDK

final class NINChatViewController: UIViewController, ViewController {
    
    private let animationDuration: Double = 0.3
    private var webRTCClient: NINWebRTCClient?
    
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
            chatRTCDelegate.onError = { [weak self] error in
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
            self?.onVideoAudioTappe(with: button)
        }
        view.onHangupTapped = { [weak self] _ in
            self?.onVideoHangupTapped()
        }
        
        return view
    }()
    @IBOutlet private weak var videoContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var videoContainer: UIView! {
        didSet {
            videoContainer.addSubview(videoView)
            videoView
                .fix(left: (0.0, videoContainer), right: (0.0, videoContainer), isRelative: false)
                .fix(top: (0.0, videoContainer), bottom: (0.0, videoContainer), isRelative: false)
        }
    }
    
    @IBOutlet private weak var chatContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var chatView: NINChatView! {
        didSet {
            /// TODO: Update after migration of `NINChatView`
            chatView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:))))
            chatView.sessionManager = session.sessionManager
            chatView.delegate = chatDataSourceDelegate
            chatView.dataSource = chatDataSourceDelegate
        }
    }
    @IBOutlet private weak var closeChatButton: NINCloseChatButton! {
        didSet {
            let closeTitle = self.session.sessionManager.translation(Constants.kCloseChatText.rawValue, formatParams: [:])
            closeChatButton.setButtonTitle(closeTitle)
            closeChatButton.overrideAssets(with: self.session)
            closeChatButton.pressedCallback = { [weak self] in
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
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(inputControlsContainerTapped(_:))))
        
        return view
    }()
    private var inputContainerHeight: CGFloat!
    @IBOutlet private weak var inputContainer: UIView! {
        didSet {
            inputContainerHeight = 94.5
            inputContainer.addSubview(inputControlsView)
            inputControlsView
                .fix(left: (0.0, inputContainer), right: (0.0, inputContainer), isRelative: false)
                .fix(top: (0.0, inputContainer), bottom: (0.0, inputContainer), isRelative: false)
        }
    }
    
    // MARK: - UIViewController
    
    override var prefersStatusBarHidden: Bool {
        // Prefer no status bar if video is active
        return webRTCClient != nil
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
        self.stopChatObservers()
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
            #if DEBUG
            print("new text area height: \(height + 64)")
            #endif
            
            self?.updateInputContainerHeight(height + 64.0)
        }
    }
    
    // MARK: - Setup ViewModel
    
    private func setupViewModel() {
        self.viewModel.onChannelClosed = { [weak self] in
            self?.stopChatObservers()
            self?.disableView()
        }
        self.viewModel.onQueued = { [weak self] in
            self?.stopChatObservers()
            self?.disableView()
            self?.onBackToQueue?()
        }
        self.viewModel.onChannelMessage = { [weak self] update in
            switch update {
            case .insert(let index):
                self?.chatView.newMessageWasAdded(at: index)
            case .remove(let index):
                self?.chatView.messageWasRemoved(at: index)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func connectRTC() {
        self.viewModel.listenToRTCSignaling(delegate: chatRTCDelegate, onCallReceived: { [unowned self] channel in
            self.view.endEditing(true)
            NINVideoCallConsentDialog.show(on: self.view, forRemoteUser: channel, sessionManager: self.session.sessionManager) { result in
                self.viewModel.pickup(answer: result == .accepted) { error in
                    if error != nil { NINToast.showWithErrorMessage("failed to send WebRTC pickup message", callback: nil) }
                }
            }
            
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
    /// Capturing `[weak self]` while deallocating result in crash
    private func deallocRTC() {
        self.viewModel.disconnectRTC(self.webRTCClient, completion: nil)
    }
    
    private func stopChatObservers() {
        if let observer = self.viewModel.signalingObserver {
            NotificationCenter.default.removeObserver(observer)
            self.viewModel.signalingObserver = nil
        }
        
        if let observer = self.viewModel.messageObserver {
            NotificationCenter.default.removeObserver(observer)
            self.viewModel.messageObserver = nil
        }
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
        self.inputContainer.deactivate(size: [.height])
        self.inputContainer.fix(height: value)
        
        if update {
            self.inputContainerHeight = value
        }
        self.view.layoutIfNeeded()
    }
    
    // Aligns (or cancels existing alignment) the input control container view's top
    // to the screen bottom to hide the controls.
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
        
        UIView.animate(withDuration: animation ? animationDuration : 0.0) {
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
        #if DEGBU
        print("Close chat button pressed!")
        #endif
        
        NINConfirmCloseChatDialog.show(on: self.view, sessionManager: self.session.sessionManager) { [weak self] result in
            guard result == .close else { return }
            
            self?.stopChatObservers()
            self?.disconnectRTC()
            self?.onChatClosed?()
        }
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
        if button.isSelected {
            guard self.webRTCClient?.enableLocalVideo() ?? false else { return }
            self.session.ninchat(session, didOutputSDKLog: "Video enabled")
        } else {
            guard self.webRTCClient?.disableLocalVideo() ?? false else { return }
            self.session.ninchat(session, didOutputSDKLog: "Video disabled")
        }
        button.isSelected = !button.isSelected
    }
    
    private func onVideoAudioTappe(with button: UIButton) {
        if button.isSelected {
            guard self.webRTCClient?.unmuteLocalAudio() ?? false else { return }
            self.session.ninchat(session, didOutputSDKLog: "Audio unmuted")
        } else {
            guard self.webRTCClient?.muteLocalAudio() ?? false else { return }
            self.session.ninchat(session, didOutputSDKLog: "Audio muted")
        }
        button.isSelected = !button.isSelected
    }
    
    private func onVideoHangupTapped() {
        self.session.ninchat(session, didOutputSDKLog: "Hang-up button pressed")
        self.viewModel.send(type: WebRTCConstants.kNINMessageTypeWebRTCHangup.rawValue, payload: [:]) { [weak self] error in
            self?.disconnectRTC {
                self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
            }
        }
    }
}

// MARK: - Notifications handlers

extension NINChatViewController {
    override func keyboardWillShow(notification: Notification) {
        super.keyboardWillShow(notification: notification)
        self.viewModel.updateWriting(state: true)
    }
    
    override func keyboardWillHide(notification: Notification) {
        super.keyboardWillHide(notification: notification)
        self.viewModel.updateWriting(state: false)
    }
    
    override func orientationChanged(notification: Notification) {
        /// TODO: figure-out why they had passed a global variable and reset it
        self.videoView.resizeRemoteVideo()
        self.videoView.resizeLocalVideo()
    }
    
    @objc
    private func didEnterBackground(notification: Notification) {
        viewModel.appDidEnterBackground { [weak self] error in
            #if DEBUG
            if let error = error {
                print("failed to send hang-up: \(error)")
            }
            #endif
            
            self?.view.endEditing(true)
            self?.disconnectRTC {
                self?.adjustConstraints(for: self?.view.bounds.size ?? .zero, withAnimation: true)
            }
        }
    }
    
    @objc
    private func willResignActive(notification: Notification) {
        #if DEBUG
        print("applicationWillResignActive: no action.")
        #endif
        
        /// TODO: pause video - if one should be active - here?
        viewModel.appWillResignActive { _ in }
    }
}
