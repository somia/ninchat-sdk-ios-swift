//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQueueViewController: UIViewController, ViewController, HasCustomLayer, HasTitleBar {

    // MARK: - Injected

    var viewModel: NINQueueViewModel!
    var queue: Queue!
    var resumeMode: ResumeMode?
    var onQueueActionTapped: ((Queue?) -> Void)?
    private var queueTransferListener: AnyHashable!
    
    // MARK: - ViewController
    
    weak var delegate: NINChatSessionInternalDelegate?
    weak var sessionManager: NINChatSessionManager?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var topContainerView: UIView!
    @IBOutlet private(set) weak var bottomContainerView: UIView!
    @IBOutlet private(set) weak var spinnerImageView: UIImageView!
    @IBOutlet private(set) weak var queueInfoTextView: UITextView! {
        didSet {
            if let textTopColor = self.delegate?.override(colorAsset: .ninchatColorTextTop) {
                self.queueInfoTextView.textColor = textTopColor
            }
            queueInfoTextView.isHidden = true
            queueInfoTextView.delegate = self
        }
    }
    @IBOutlet private(set) weak var motdTextView: UITextView! {
        didSet {
            motdTextView.delegate = self
        }
    }
    @IBOutlet private(set) weak var cancelQueueButton: CloseButton! {
        didSet {
            cancelQueueButton.isHidden = hasTitlebar

            let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:])
            cancelQueueButton.buttonTitle = closeTitle
            cancelQueueButton.overrideAssets(with: self.delegate)
            cancelQueueButton.closure = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.onCancelQueueTapped()
                }
            }
        }
    }

    // MARK: - HasTitleBar

    @IBOutlet private(set) weak var titlebar: UIView?
    @IBOutlet private(set) weak var titlebarContainer: UIView?
    private(set) var titlebarAvatar: String? = nil   /// show placeholder
    private(set) var titlebarName: String? = nil     /// show placeholder
    private(set) var titlebarJob: String? = nil      /// show placeholder

    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitleBar(parent: self.topContainerView, adjustToSafeArea: false) { [weak self] in
            DispatchQueue.main.async {
                self?.onCancelQueueTapped()
            }
        }
        self.overrideAssets()

        NotificationCenter.default.addObserver(self, selector: #selector(spin(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        self.navigationItem.setHidesBackButton(true, animated: false)

        /// When the queue is not usable, do not try to connect
        /// instead, try to register audience if it is set in the config
        /// `https://github.com/somia/mobile/issues/337`
        if self.setupClosedQueue() {
            if let audienceRegister = self.sessionManager?.siteConfiguration.audienceRegisteredText, !audienceRegister.isEmpty {
                self.setupViewModel(.registerAudience)
            }
            return
        }
        self.setupOpenQueue()
        self.setupViewModel(self.resumeMode)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let titlebar = self.titlebar {
            applyLayerOverride(view: titlebar)
        }
        applyLayerOverride(view: self.topContainerView)
        applyLayerOverride(view: self.bottomContainerView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.spin(notification: nil)
    }

    deinit {
        debugger("`NINQueueViewController` deallocated")
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func setupViewModel(_ resumeMode: ResumeMode?) {
        self.viewModel.onInfoTextUpdate = { [weak self] text in
            DispatchQueue.main.async {
                self?.queueInfoTextView.setAttributed(text: text ?? "", font: .ninchat)
            }
        }
        self.viewModel.onQueueJoin = { [weak self] error in
            guard error == nil else { return }
            self?.onQueueActionTapped?(self?.sessionManager?.describedQueue)
        }
        /// Directly open chat page if it is a session resumption condition
        switch resumeMode {
        case .toQueue(let target):
            guard let queue = target else { return }
            self.viewModel.resumeMode = true
            self.viewModel.connect(queue: queue)
            self.queueInfoTextView.isHidden = false
            self.queueInfoTextView.setAttributed(text: self.viewModel.queueTextInfo(queue: queue, 1) ?? "", font: .ninchat)
        case .toChannel:
            self.viewModel.resumeMode = true
            guard let describedQueue = self.sessionManager?.describedQueue else {
                debugger("error in getting target queue")
                self.spinnerImageView.isHidden = true
                self.queueInfoTextView.isHidden = false
                self.queueInfoTextView.setAttributed(text: "Resume error".localized, font: .ninchat)
                return
            }
            debugger("target queue is ready: \(String(describing: describedQueue))")
            self.onQueueActionTapped?(describedQueue)
        case .registerAudience:
            self.viewModel.resumeMode = false
            self.viewModel.registerAudience(queue: self.queue)
        default:
            self.viewModel.resumeMode = false
            self.viewModel.connect(queue: self.queue)
            self.queueInfoTextView.isHidden = false
            self.queueInfoTextView.setAttributed(text: self.viewModel.queueTextInfo(queue: queue, 1) ?? "", font: .ninchat)
        }
    }

    private func setupClosedQueue() -> Bool {
        /// `If customer resumes to a session and is already in queue, then show queueing view even if queue is closed`
        if let queue = queue, queue.isClosed, queue.position == 0 {
            /// Currently, we do not have a key for closed-queue situations, leave it empty
            self.spinnerImageView.isHidden = true
            self.queueInfoTextView.isHidden = true
            self.motdTextView.setAttributed(text: self.sessionManager?.siteConfiguration.motd ?? "", font: .ninchat)
            return true
        }
        return false
    }

    private func setupOpenQueue() {
        self.spinnerImageView.isHidden = false
        self.motdTextView.setAttributed(text: self.sessionManager?.siteConfiguration.motd ?? self.sessionManager?.siteConfiguration.inQueue ?? "", font: .ninchat)
    }
}

// MARK: - Helper methods

extension NINQueueViewController {
    @objc
    private func spin(notification: Notification?) {
        guard spinnerImageView.layer.animation(forKey: "SpinAnimation") == nil else { return }
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0.0
        animation.toValue = 2.0 * .pi
        animation.duration = 3.0
        animation.repeatCount = .infinity
        spinnerImageView.layer.add(animation, forKey: "SpinAnimation")
    }

    private func overrideAssets() {
        overrideTitlebarAssets()
        cancelQueueButton.overrideAssets(with: self.delegate)

        if let spinnerImage = self.delegate?.override(imageAsset: .ninchatIconLoader) {
            self.spinnerImageView.image = spinnerImage
        }

        if let layer = self.delegate?.override(layerAsset: .ninchatBackgroundTop) {
            topContainerView.layer.insertSublayer(layer, at: 0)
        }
        /// TODO: REMOVE legacy delegate
        else if let topBackgroundColor = self.delegate?.override(colorAsset: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        
        if let layer = self.delegate?.override(layerAsset: .ninchatBackgroundBottom) {
            bottomContainerView.layer.insertSublayer(layer, at: 0)
        }
        /// TODO: REMOVE legacy delegate
        else if let bottomBackgroundColor = self.delegate?.override(colorAsset: .backgroundBottom) {
            bottomContainerView.backgroundColor = bottomBackgroundColor
        }
        
        if let textTopColor = self.delegate?.override(colorAsset: .ninchatColorTextTop) {
            queueInfoTextView.textColor = textTopColor
        }
        if let textBottomColor = self.delegate?.override(colorAsset: .ninchatColorTextBottom) {
            motdTextView.textColor = textBottomColor
        }
        
        if let linkColor = self.delegate?.override(colorAsset: .ninchatColorLink) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            queueInfoTextView.linkTextAttributes = attribute
            motdTextView.linkTextAttributes = attribute
        }
    }
}

// MARK: - User actions

extension NINQueueViewController {
    private func onCancelQueueTapped() {
        debugger("cancel queue")
        try? self.sessionManager?.closeChat { [weak self] in
            self?.sessionManager?.deallocateSession()
        }
    }
}
