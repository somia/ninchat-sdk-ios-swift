//
// Copyright (c) 20.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ConfirmVideoCallViewProtocol: ConfirmView {
    var user: ChannelUser? { get set }
}

final class ConfirmVideoCallView: UIView, ConfirmVideoCallViewProtocol {
    
    // MARK: - Outlets
    @IBOutlet private(set) weak var headerContainerView: UIView!
    @IBOutlet private(set) weak var bottomContainerView: UIView!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.round()
        }
    }
    @IBOutlet private(set) weak var usernameLabel: UILabel!
    @IBOutlet private(set) weak var infoLabel: UILabel!
    @IBOutlet private(set) weak var acceptButton: Button! {
        didSet {
            acceptButton.round(borderWidth: 1.0)
        }
    }
    @IBOutlet private(set) weak var rejectButton: Button! {
        didSet {
            rejectButton.round(borderWidth: 1.0, borderColor: .defaultBackgroundButton)
        }
    }
    
    // MARK: - ConfirmVideoCallViewProtocol
    
    var user: ChannelUser?
    
    // MARK: - ConfirmView
    
    var onViewAction: OnViewAction?
    weak var session: NINChatSession? {
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
        let agentAvatarConfig = AvatarConfig(avatar: sessionManager.siteConfiguration.agentAvatar, name: sessionManager.siteConfiguration.agentName)
        
        /// Caller's Avatar image
        if let overrideURL = agentAvatarConfig.imageOverrideURL {
            self.avatarImageView.image(from: overrideURL)
        } else if let iconURL = user?.iconURL {
            self.avatarImageView.image(from: iconURL)
        } else if let bundle = Bundle.SDKBundle {
            self.avatarImageView.image = UIImage(named: "icon_avatar_other", in: bundle, compatibleWith: nil)
        }
        
        /// Caller's name
        if !agentAvatarConfig.nameOverride.isEmpty {
            self.usernameLabel.text = agentAvatarConfig.nameOverride
        } else if let user = user {
            self.usernameLabel.text = user.displayName
        } else {
            self.usernameLabel.text = "Guest".localized
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
