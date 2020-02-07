//
// Copyright (c) 20.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

protocol ConfirmVideoCallViewProtocol: ConfirmView {
    var user: NINChannelUser! { get set }
}

final class ConfirmVideoCallView: UIView, ConfirmVideoCallViewProtocol {
    
    // MARK: - Outlets
    @IBOutlet private weak var headerContainerView: UIView!
    @IBOutlet private weak var bottomContainerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.round()
        }
    }
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var acceptButton: Button! {
        didSet {
            acceptButton.round(1.0)
        }
    }
    @IBOutlet private weak var rejectButton: Button! {
        didSet {
            rejectButton.round(1.0, .defaultBackgroundButton)
        }
    }
    
    // MARK: - ConfirmVideoCallViewProtocol
    
    var user: NINChannelUser!
    
    // MARK: - ConfirmView
    
    var onViewAction: OnViewAction?
    weak var session: NINChatSessionSwift? {
        didSet {
            self.overrideAssets()
        }
    }
    
    func overrideAssets() {
        acceptButton.overrideAssets(with: self.session, isPrimary: true)
        rejectButton.overrideAssets(with: self.session, isPrimary: false)
        
        if let backgroundColor = self.session?.override(colorAsset: .modalBackground) {
            self.headerContainerView.backgroundColor = backgroundColor
            self.bottomContainerView.backgroundColor = backgroundColor
        }
        
        if let textColor = self.session?.override(colorAsset: .modalText) {
            self.titleLabel.textColor = textColor
            self.usernameLabel.textColor = textColor
            self.infoLabel.textColor = textColor
        }

        guard let sessionManager = session?.sessionManager else { return }
        let agentAvatarConfig = NINAvatarConfig(avatar: sessionManager.siteConfiguration.agentAvatar ?? "", name: sessionManager.siteConfiguration.agentName ?? "")
        
        /// Caller's Avatar image
        if !agentAvatarConfig.imageOverrideUrl.isEmpty {
            self.avatarImageView.setImageURL(agentAvatarConfig.imageOverrideUrl)
        } else if !user.iconURL.isEmpty {
            self.avatarImageView.setImageURL(user.iconURL)
        }
        
        /// Caller's name
        if !agentAvatarConfig.nameOverride.isEmpty {
            self.usernameLabel.text = agentAvatarConfig.nameOverride
        } else {
            self.usernameLabel.text = user.displayName
        }

        
        if let acceptTitle = sessionManager.translate(key: Constants.kAcceptDialog.rawValue, formatParams: [:]) {
            self.acceptButton.setTitle(acceptTitle, for: .normal)
        }
        
        if let rejectTitle = sessionManager.translate(key: Constants.kRejectDialog.rawValue, formatParams: [:]) {
            self.rejectButton.setTitle(rejectTitle, for: .normal)
        }
        
        if let title = sessionManager.translate(key: Constants.kCallInvitationText.rawValue, formatParams: [:]) {
            self.titleLabel.text = title
        }
        
        if let info = sessionManager.translate(key: Constants.kCallInvitationInfoText.rawValue, formatParams: [:]) {
            self.infoLabel.text = info
        }
    }
    
    // MARK: - User actions
    
    @IBAction private func onAcceptButtonTapped(sender: UIButton) {
        onViewAction?(.confirm)
    }
    
    @IBAction private func onCancelButtonTapped(sender: UIButton) {
        onViewAction?(.cancel)
    }
}
