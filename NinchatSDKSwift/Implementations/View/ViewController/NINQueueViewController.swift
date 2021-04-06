//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQueueViewController: UIViewController, ViewController {
    
    // MARK: - Injected

    var viewModel: NINQueueViewModel!
    var queue: Queue!
    var resumeMode: ResumeMode?
    var onQueueActionTapped: ((Queue?) -> Void)?
    private var queueTransferListener: AnyHashable!
    
    // MARK: - ViewController
    
    var delegate: InternalDelegate?
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
            queueInfoTextView.text = nil
            queueInfoTextView.delegate = self
        }
    }
    @IBOutlet private(set) weak var motdTextView: UITextView! {
        didSet {
            if let queueText = self.sessionManager?.siteConfiguration.inQueue {
                motdTextView.setAttributed(text: queueText, font: .ninchat)
            } else if let motdText = self.sessionManager?.siteConfiguration.motd {
                motdTextView.setAttributed(text: motdText, font: .ninchat)
            }
            motdTextView.delegate = self
        }
    }
    @IBOutlet private(set) weak var closeChatButton: CloseButton! {
        didSet {
            let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:])
            closeChatButton.buttonTitle = closeTitle
            closeChatButton.overrideAssets(with: self.delegate)
            closeChatButton.closure = { [weak self] button in
                try? self?.sessionManager?.closeChat {
                    self?.sessionManager?.deallocateSession()
                }
            }
        }
    }
    
    // MARK: - UIViewController
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupClosedQueue()
        self.setupViewModel()
        self.overrideAssets()

        NotificationCenter.default.addObserver(self, selector: #selector(spin(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        self.navigationItem.setHidesBackButton(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.spin(notification: nil)
    }

    deinit {
        debugger("`NINQueueViewController` deallocated")
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func setupViewModel() {
        self.viewModel.resumeMode = self.resumeMode != nil
        self.viewModel.onInfoTextUpdate = { [weak self] text in
            self?.updateQueueInfo(text: text)
        }
        self.viewModel.onQueueJoin = { [weak self] error in
            guard error == nil else { return }
            self?.onQueueActionTapped?(self?.sessionManager?.describedQueue)
        }
        /// Directly open chat page if it is a session resumption condition
        switch self.resumeMode {
        case .toQueue(let target):
            guard let queue = target else { return }
            self.viewModel.connect(queue: queue)
            self.updateQueueInfo(text: self.viewModel.queueTextInfo(queue: queue, 1))
        case .toChannel:
            if self.sessionManager?.describedQueue == nil {
                debugger("error in getting target queue")
                self.stopSpinWith(message: "Resume error".localized)
            } else {
                debugger("target queue is ready: \(String(describing: self.sessionManager?.describedQueue))")
                self.onQueueActionTapped?(self.sessionManager?.describedQueue)
            }
        default:
            self.viewModel.connect(queue: self.queue)
            self.updateQueueInfo(text: self.viewModel.queueTextInfo(queue: queue, 1))
        }
    }

    private func setupClosedQueue() {
        /// `If customer resumes to a session and is already in queue, then show queueing view even if queue is closed`
        guard let queue = queue, queue.isClosed && self.resumeMode == nil else { return }
        self.stopSpinWith(message: self.sessionManager?.siteConfiguration.noQueueText ?? "")
    }

    private func stopSpinWith(message: String) {
        self.spinnerImageView.isHidden = true
        self.queueInfoTextView.setAttributed(text: message, font: .ninchat)
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
    
    private func updateQueueInfo(text: String?) {
        DispatchQueue.main.async {
            self.queueInfoTextView.setAttributed(text: text ?? "", font: .ninchat)
        }
    }

    private func overrideAssets() {
        
        closeChatButton.overrideAssets(with: self.delegate)
        if let spinnerImage = self.delegate?.override(imageAsset: .ninchatIconLoader) {
            self.spinnerImageView.image = spinnerImage
        }
        if let topBackgroundColor = self.delegate?.override(colorAsset: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = self.delegate?.override(colorAsset: .backgroundBottom) {
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
