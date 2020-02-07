//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

final class NINInitialViewController: UIViewController, ViewController {
    
    // MARK: - Injected
    
    var onQueueActionTapped: ((NINQueue) -> Void)?
    
    // MARK: - ViewController
    
    var session: NINChatSessionSwift!
    
    // MARK: - Outlets
    
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var bottomContainerView: UIView!
    @IBOutlet private weak var welcomeTextView: UITextView! {
        didSet {
            if let welcomeText = self.session.sessionManager.siteConfiguration.welcome {
                welcomeTextView.setFormattedText(welcomeText)
                welcomeTextView.delegate = self
            }
        }
    }
    @IBOutlet private weak var queueButtonsStackView: UIStackView!
    @IBOutlet private weak var closeWindowButton: Button! {
        didSet {
            if let closeText = self.session.sessionManager.translate(key: Constants.kCloseWindowText.rawValue, formatParams: [:]) {
                closeWindowButton.setTitle(closeText, for: .normal)
            }
            closeWindowButton.round(1, .defaultBackgroundButton)
        }
    }
    @IBOutlet private weak var motdTextView: UITextView! {
        didSet {
            if let motdText = self.session.sessionManager.siteConfiguration.motd {
                motdTextView.setFormattedText(motdText)
            }
            motdTextView.delegate = self
        }
    }
    
    // MARK: - UIViewController
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.overrideAssets()
        self.drawQueueButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addKeyboardListeners()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeKeyboardListeners()
    }
    
    // MARK: - User actions
    
    @IBAction private func closeWindowButtonPressed(button: UIButton) {
        try? self.session.sessionManager.closeChat()
    }
}

// MARK: - Helper methods

private extension NINInitialViewController {
    private func overrideAssets() {
        closeWindowButton.overrideAssets(with: self.session, isPrimary: false)
        if let topBackgroundColor = session.override(colorAsset: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = session.override(colorAsset: .backgroundBottom) {
            bottomContainerView.backgroundColor = bottomBackgroundColor
        }
        if let textTopColor = session.override(colorAsset: .textTop) {
            welcomeTextView.textColor = textTopColor
        }
        if let textBottomColor = session.override(colorAsset: .textBottom) {
            motdTextView.textColor = textBottomColor
        }
        if let linkColor = session.override(colorAsset: .link) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            welcomeTextView.linkTextAttributes = attribute
            motdTextView.linkTextAttributes = attribute
        }
    }
    
    private func drawQueueButtons() {
        self.queueButtonsStackView.subviews.forEach { $0.removeFromSuperview() }
        
        let numberOfButtons = min(3, self.session.sessionManager.audienceQueues.count)
        let buttonHeights: CGFloat = (numberOfButtons > 2) ? 40.0 : 60.0
        for queue in self.session.sessionManager.queues.sorted(by: { $0.name > $1.name }) {
            guard queueButtonsStackView.subviews.count <= numberOfButtons else { return }
            let button = Button(frame: .zero) { [weak self] _ in
                self?.onQueueActionTapped?(queue)
            }
            button.translatesAutoresizingMaskIntoConstraints = false
            button.layer.cornerRadius = buttonHeights / 2
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            button.backgroundColor = .defaultBackgroundButton
            button.setTitleColor(.white, for: .normal)
            button.setTitle(self.session.sessionManager.translate(key: Constants.kJoinQueueText.rawValue, formatParams: ["audienceQueue.queue_attrs.name": queue.name]), for: .normal)
            button.overrideAssets(with: self.session, isPrimary: true)
            
            queueButtonsStackView.addArrangedSubview(button)
            button.heightAnchor.constraint(equalToConstant: buttonHeights).isActive = true
        }
    }
}
