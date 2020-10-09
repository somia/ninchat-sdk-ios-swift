//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINInitialViewController: UIViewController {
    
    // MARK: - Injected
    
    var onQueueActionTapped: ((Queue) -> Void)?
    
    // MARK: - ViewController
    
    weak var session: NINChatSession?
    weak var sessionManager: NINChatSessionManager?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) var topContainerView: UIView!
    @IBOutlet private(set) var bottomContainerView: UIView!
    @IBOutlet private(set) var welcomeTextView: UITextView! {
        didSet {
            if let welcomeText = self.sessionManager?.siteConfiguration.welcome {
                welcomeTextView.setAttributed(text: welcomeText, font: .ninchat)
                welcomeTextView.delegate = self
            }
        }
    }
    @IBOutlet private(set) var queueButtonsStackView: UIStackView!
    @IBOutlet private(set) var closeWindowButton: Button! {
        didSet {
            if let closeText = self.sessionManager?.translate(key: Constants.kCloseWindowText.rawValue, formatParams: [:]) {
                closeWindowButton.setTitle(closeText, for: .normal)
            }
            closeWindowButton.round(borderWidth: 1.0, borderColor: .defaultBackgroundButton)
        }
    }
    @IBOutlet private(set) var motdTextView: UITextView! {
        didSet {
            if let motdText = self.sessionManager?.siteConfiguration.motd {
                motdTextView.setAttributed(text: motdText, font: .ninchat)
            }
            motdTextView.delegate = self
            motdTextView.textAlignment = .left
        }
    }
    @IBOutlet private(set) var noQueueTextView: UITextView! {
        didSet {
            self.noQueueTextView.isHidden = true
        }
    }

    // MARK: - UIViewController
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.sessionManager?.audienceQueues.filter({ !$0.isClosed }).count ?? 0 > 0 {
            /// There is at least one open queue to join
            self.drawQueueButtons()
        } else {
            /// Show no queue text
            self.drawNoQueueText()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.overrideAssets()
    }

    // MARK: - User actions
    
    @IBAction private func closeWindowButtonPressed(button: UIButton) {
        self.session?.internalDelegate?.onDidEnd()
    }
}

// MARK: - Helper methods

private extension NINInitialViewController {
    private func overrideAssets() {
        closeWindowButton?.overrideAssets(with: self.session?.internalDelegate, isPrimary: false)
        if let topBackgroundColor = self.session?.internalDelegate?.override(colorAsset: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = self.session?.internalDelegate?.override(colorAsset: .backgroundBottom) {
            bottomContainerView.backgroundColor = bottomBackgroundColor
        }
        if let textTopColor = self.session?.internalDelegate?.override(colorAsset: .textTop) {
            welcomeTextView.textColor = textTopColor
        }
        if let textBottomColor = self.session?.internalDelegate?.override(colorAsset: .textBottom) {
            motdTextView.textColor = textBottomColor
        }
        if let linkColor = self.session?.internalDelegate?.override(colorAsset: .link) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            welcomeTextView.linkTextAttributes = attribute
            motdTextView.linkTextAttributes = attribute
        }
    }
    
    private func drawQueueButtons() {
        self.queueButtonsStackView.subviews.forEach { $0.removeFromSuperview() }

        let availableQueues = self.sessionManager?.audienceQueues.filter({ !$0.isClosed }) ?? []
        let numberOfButtons = min(3, availableQueues.count)
        let buttonHeights: CGFloat = (numberOfButtons > 2) ? 40.0 : 60.0
        for index in 0..<numberOfButtons {
            let queue = availableQueues[index]
            let button = Button(frame: .zero) { [weak self] _ in
                self?.onQueueActionTapped?(queue)
            }
            button.translatesAutoresizingMaskIntoConstraints = false
            button.layer.cornerRadius = buttonHeights / 2
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            button.backgroundColor = .defaultBackgroundButton
            button.setTitleColor(.white, for: .normal)
            button.setTitle(self.sessionManager?.translate(key: Constants.kJoinQueueText.rawValue, formatParams: ["audienceQueue.queue_attrs.name": queue.name]) ?? "", for: .normal)
            button.overrideAssets(with: self.session?.internalDelegate, isPrimary: true)
            
            queueButtonsStackView.addArrangedSubview(button)
            button.heightAnchor.constraint(equalToConstant: buttonHeights).isActive = true
        }
    }

    private func drawNoQueueText() {
        self.queueButtonsStackView.isHidden = true
        self.noQueueTextView.isHidden = false
        self.noQueueTextView.setAttributed(text: self.sessionManager?.siteConfiguration.noQueueText ?? NSLocalizedString("NoQueueText", tableName: "Localizable", bundle: Bundle.SDKBundle!, value: "", comment: ""), font: self.noQueueTextView.font)
    }
}
