//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQueueViewController: UIViewController {
    
    // MARK: - Injected
    
    var viewModel: NINQueueViewModel!
    var queue: Queue!
    var resumeMode: Bool!
    var onQueueActionTapped: ((Queue?) -> Void)?
    private var queueTransferListener: AnyHashable!
    
    // MARK: - ViewController
    
    weak var session: NINChatSession?
    weak var sessionManager: NINChatSessionManager?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var topContainerView: UIView!
    @IBOutlet private(set) weak var bottomContainerView: UIView!
    @IBOutlet private(set) weak var spinnerImageView: UIImageView!
    @IBOutlet private(set) weak var queueInfoTextView: UITextView! {
        didSet {
            if let textTopColor = self.session?.internalDelegate?.override(colorAsset: .textTop) {
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
            closeChatButton.overrideAssets(with: self.session?.internalDelegate)
            closeChatButton.buttonTitle = closeTitle
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
        self.setupViewModel()
        self.overrideAssets()

        NotificationCenter.default.addObserver(self, selector: #selector(spin(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
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
        self.viewModel.resumeMode = self.resumeMode
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
        (self.resumeMode) ? self.onQueueActionTapped?(self.sessionManager?.describedQueue) : self.viewModel.connect(queue: self.queue)
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
        
        closeChatButton.overrideAssets(with: self.session?.internalDelegate)
        if let spinnerImage = self.session?.internalDelegate?.override(imageAsset: .iconLoader) {
            self.spinnerImageView.image = spinnerImage
        }
        if let topBackgroundColor = self.session?.internalDelegate?.override(colorAsset: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = self.session?.internalDelegate?.override(colorAsset: .backgroundBottom) {
            bottomContainerView.backgroundColor = bottomBackgroundColor
        }
        if let textTopColor = self.session?.internalDelegate?.override(colorAsset: .textTop) {
            queueInfoTextView.textColor = textTopColor
        }
        if let textBottomColor = self.session?.internalDelegate?.override(colorAsset: .textBottom) {
            motdTextView.textColor = textBottomColor
        }
        if let linkColor = self.session?.internalDelegate?.override(colorAsset: .link) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            queueInfoTextView.linkTextAttributes = attribute
            motdTextView.linkTextAttributes = attribute
        }
    }
}
