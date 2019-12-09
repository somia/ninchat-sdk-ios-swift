//
//  NINQueueViewController.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit
import NinchatSDK

final class NINQueueViewController: UIViewController, ViewController {
    
    var onQueueActionTapped: (() -> Void)?
    private var queueTransferListener: AnyHashable!
    
    // MARK: - ViewController
    
    var session: NINChatSessionSwift!
    var queueToJoin: NINQueue!
    
    // MARK: - Outlets
    
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var bottomContainerView: UIView!
    @IBOutlet private weak var spinnerImageView: UIImageView!
    @IBOutlet private weak var queueInfoTextView: UITextView! {
        didSet {
            queueInfoTextView.text = nil
            queueInfoTextView.delegate = self
        }
    }
    @IBOutlet private weak var motdTextView: UITextView! {
        didSet {
            if let queueText = self.session.sessionManager.siteConfiguration.inQueue {
                motdTextView.setFormattedText(queueText)
            } else if let motdText = self.session.sessionManager.siteConfiguration.motd {
                motdTextView.setFormattedText(motdText)
            }
            motdTextView.delegate = self
        }
    }
    @IBOutlet private weak var closeChatButton: NINCloseChatButton! {
        didSet {
            if let closeText = self.session.sessionManager.translation(Constants.kCloseChatText.rawValue, formatParams: [:]) {
                closeChatButton.setButtonTitle(closeText)
            }
            closeChatButton.pressedCallback = { [weak self] in
                self?.session.sessionManager.leaveCurrentQueue { _ in
                    self?.session.sessionManager.closeChat()
                }
            }
        }
    }
    
    // MARK: - UIViewController
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideAssets()
        self.connect(to: self.queueToJoin.queueID)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addKeyboardListeners()
        self.spin()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeKeyboardListeners()
    }
}

// MARK: - Helper methods

private extension NINQueueViewController {
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
        if let topBackgroundColor = session.overrideColorAsset(forKey: .backgroundTop) {
            topContainerView.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = session.overrideColorAsset(forKey: .backgroundBottom) {
            bottomContainerView.backgroundColor = bottomBackgroundColor
        }
        if let textTopColor = session.overrideColorAsset(forKey: .textTop) {
            queueInfoTextView.textColor = textTopColor
        }
        if let textBottomColor = session.overrideColorAsset(forKey: .textBottom) {
            motdTextView.textColor = textBottomColor
        }
        if let linkColor = session.overrideColorAsset(forKey: .link) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            queueInfoTextView.linkTextAttributes = attribute
            motdTextView.linkTextAttributes = attribute
        }
    }
    
    private func connect(to queueID: String) {
        self.session.sessionManager.joinQueue(withId: queueID, progress: { [weak self] error, progress in
            if let error = error {
                self?.session.log(format: "Failed to join the queue: %@", error.localizedDescription)
            }
            DispatchQueue.main.async {
                self?.updateQueueTextInfo(progress)
                if let textTopColor = self?.session.override(colorAsset: .textTop) {
                    self?.queueInfoTextView.textColor = textTopColor
                }
            }
        }, channelJoined: { [weak self] in
            self?.onQueueActionTapped?()
        })
    }
    
    private func updateQueueTextInfo(_ progress: Int) {
        switch progress {
        case 1:
            let position = session.sessionManager.translation(Constants.kQueuePositionNext.rawValue,
                                                              formatParams: ["audienceQueue.queue_attrs.name": "\(progress)"])
            queueInfoTextView.setFormattedText(position ?? "")
        default:
            let position = session.sessionManager.translation(Constants.kQueuePositionN.rawValue,
                                                              formatParams: ["audienceQueue.queue_position": "\(progress)"])
            queueInfoTextView.setFormattedText(position ?? "")
        }
    }
}
