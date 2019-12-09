//
//  NINInitialViewController.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
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
    @IBOutlet private weak var closeWindowButton: NINButton! {
        didSet {
            if let closeText = self.session.sessionManager.translation(Constants.kCloseWindowText.rawValue, formatParams: [:]) {
                closeWindowButton.setTitle(closeText, for: .normal)
            }
            closeWindowButton.layer.cornerRadius = closeWindowButton.bounds.height / 2
            closeWindowButton.layer.borderColor = UIColor.defaultBackgroundButton.cgColor
            closeWindowButton.layer.borderWidth = 1
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
        self.session.sessionManager.closeChat()
    }
}

// MARK: - Helper methods

private extension NINInitialViewController {
    private func overrideAssets() {
        closeWindowButton.overrideAssets(with: self.session, isPrimary: false)
        if let topBackgroundColor = session.overrideColorAsset(forKey: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = session.overrideColorAsset(forKey: .backgroundBottom) {
            bottomContainerView.backgroundColor = bottomBackgroundColor
        }
        if let textTopColor = session.overrideColorAsset(forKey: .textTop) {
            welcomeTextView.textColor = textTopColor
        }
        if let textBottomColor = session.overrideColorAsset(forKey: .textBottom) {
            motdTextView.textColor = textBottomColor
        }
        if let linkColor = session.overrideColorAsset(forKey: .link) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            welcomeTextView.linkTextAttributes = attribute
            motdTextView.linkTextAttributes = attribute
        }
    }
    
    private func drawQueueButtons() {
        self.queueButtonsStackView.subviews.forEach { $0.removeFromSuperview() }
        
        let numberOfButtons = min(3, self.session.sessionManager.audienceQueues.count)
        let buttonHeights: CGFloat = (numberOfButtons > 2) ? 40.0 : 60.0
        for queue in self.session.sessionManager.queues {
            guard queueButtonsStackView.subviews.count <= numberOfButtons else { return }
            let button = NINButton(frame: .zero) { [weak self] _ in
                self?.onQueueActionTapped?(queue)
            }
            button.translatesAutoresizingMaskIntoConstraints = false
            button.layer.cornerRadius = buttonHeights / 2
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            button.backgroundColor = .defaultBackgroundButton
            button.setTitleColor(.white, for: .normal)
            button.setTitle(self.session.sessionManager.translation(Constants.kJoinQueueText.rawValue,
                                                            formatParams: ["audienceQueue.queue_attrs.name": queue.name]), for: .normal)
            button.overrideAssets(with: self.session, isPrimary: true)
            
            queueButtonsStackView.addArrangedSubview(button)
            button.heightAnchor.constraint(equalToConstant: buttonHeights).isActive = true
        }
    }
}
