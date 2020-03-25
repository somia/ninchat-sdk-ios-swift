//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQueueViewController: UIViewController, ViewController {
    
    private var sessionManager: NINChatSessionManager {
        session.sessionManager
    }
    
    // MARK: - Injected
    
    var viewModel: NINQueueViewModel!
    var queue: Queue!
    var onQueueActionTapped: (() -> Void)?
    private var queueTransferListener: AnyHashable!
    
    // MARK: - ViewController
    
    var session: NINChatSessionSwift!
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var topContainerView: UIView!
    @IBOutlet private(set) weak var bottomContainerView: UIView!
    @IBOutlet private(set) weak var spinnerImageView: UIImageView!
    @IBOutlet private(set) weak var queueInfoTextView: UITextView! {
        didSet {
            if let textTopColor = self.session.override(colorAsset: .textTop) {
                self.queueInfoTextView.textColor = textTopColor
            }
            queueInfoTextView.text = nil
            queueInfoTextView.delegate = self
        }
    }
    @IBOutlet private(set) weak var motdTextView: UITextView! {
        didSet {
            if let queueText = self.sessionManager.siteConfiguration.inQueue {
                motdTextView.setAttributed(text: queueText, font: .ninchat)
            } else if let motdText = self.sessionManager.siteConfiguration.motd {
                motdTextView.setAttributed(text: motdText, font: .ninchat)
            }
            motdTextView.delegate = self
        }
    }
    @IBOutlet private(set) weak var closeChatButton: CloseButton! {
        didSet {
            let closeTitle = self.session.sessionManager.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:])
            closeChatButton.buttonTitle = closeTitle
            closeChatButton.overrideAssets(with: self.session)
            closeChatButton.closure = { [weak self] button in
                self?.sessionManager.leave { _ in
                    try? self?.sessionManager.closeChat()
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.spin()
    }

    private func setupViewModel() {
        self.viewModel.onInfoTextUpdate = { [weak self] text in
            DispatchQueue.main.async {
                self?.queueInfoTextView.setAttributed(text: text ?? "", font: .ninchat)
            }
        }
        self.viewModel.onQueueJoin = { [weak self] error in
            guard error == nil else { return }

            DispatchQueue.main.async {
                self?.onQueueActionTapped?()
            }
        }
        self.viewModel.connect(queue: self.queue)
    }
}

// MARK: - Helper methods

extension NINQueueViewController {
    private func spin() {
        guard spinnerImageView.layer.animation(forKey: "SpinAnimation") == nil else { return }
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0.0
        animation.toValue = 2.0 * .pi
        animation.duration = 3.0
        animation.repeatCount = .infinity
        spinnerImageView.layer.add(animation, forKey: "SpinAnimation")
    }
    
    private func overrideAssets() {
        closeChatButton.overrideAssets(with: self.session)
        
        if let spinnerImage = session.override(imageAsset: .iconLoader) {
            self.spinnerImageView.image = spinnerImage
        }
        if let topBackgroundColor = session.override(colorAsset: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = session.override(colorAsset: .backgroundBottom) {
            bottomContainerView.backgroundColor = bottomBackgroundColor
        }
        if let textTopColor = session.override(colorAsset: .textTop) {
            queueInfoTextView.textColor = textTopColor
        }
        if let textBottomColor = session.override(colorAsset: .textBottom) {
            motdTextView.textColor = textBottomColor
        }
        if let linkColor = session.override(colorAsset: .link) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            queueInfoTextView.linkTextAttributes = attribute
            motdTextView.linkTextAttributes = attribute
        }
    }
}
