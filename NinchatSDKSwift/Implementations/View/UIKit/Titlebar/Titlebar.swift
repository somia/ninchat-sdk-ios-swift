//
// Copyright (c) 10.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class Titlebar: UIView {

    // MARK: - Injected
    
    var onCloseTapped: (() -> Void)?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var agentAvatarContainer: UIView! {
        didSet {
            agentAvatarContainer.round(borderWidth: 1.0, borderColor: .clear)
            agentAvatarContainer.backgroundColor = .tPlaceholderGray
        }
    }
    @IBOutlet private(set) weak var agentAvatarImageView: UIImageView!
    @IBOutlet private(set) weak var agentInfoStackView: UIStackView!
    @IBOutlet private(set) weak var agentInfoPlaceholder: UIView! {
        didSet {
            agentInfoPlaceholder.round(radius: 5.0, borderWidth: 1.0, borderColor: .clear)
            agentInfoPlaceholder.backgroundColor = .tPlaceholderGray
        }
    }
    @IBOutlet private(set) weak var agentNameLabel: UILabel! {
        didSet {
            agentNameLabel.font = .ninchatSemiBold
        }
    }
    @IBOutlet private(set) weak var agentJobLabel: UILabel! {
        didSet {
            agentJobLabel.font = .ninchatLight
        }
    }
    @IBOutlet private(set) weak var closeButton: CloseButton! {
        didSet {
            closeButton.closure = { [weak self] _ in
                self?.onCloseTapped?()
            }
        }
    }
    
    // MARK: - UIView
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
    }
    
    // MARK: - Setup View
    
    func setupView(_ session: NINChatSessionManager?, view: HasTitleBar, defaultAvatarView: HasDefaultAvatar?) {
        if let name = view.titlebarName, !name.isEmpty {
            /// show titlebar
            agentInfoPlaceholder.isHidden = true
            
            agentNameLabel.text = name
        } else {
            /// show placeholder
            agentInfoStackView.isHidden = true
        }
        
        if let job = view.titlebarJob, !job.isEmpty {
            agentJobLabel.text = job
        } else {
            /// Hide job if not available
            agentJobLabel.isHidden = true
        }
        
        if agentInfoStackView.isHidden {
            /// show placeholder if name is hidden
            agentAvatarImageView.isHidden = true
        } else if let avatarImage = view.titlebarAvatar, !avatarImage.isEmpty {
            /// don't show avatar if config.agentAvatar = false
            guard let agentAvatar = session?.siteConfiguration.agentAvatar as? Bool, agentAvatar else {
                agentAvatarContainer.isHidden = true
                return
            }
            agentAvatarContainer.backgroundColor = .white
            agentAvatarImageView.image(from: avatarImage)
        } else if let defaultAvatar = defaultAvatarView?.defaultAvatar {
            agentAvatarContainer.backgroundColor = .white
            agentAvatarImageView.image = defaultAvatar
        } else {
            agentAvatarContainer.isHidden = true
        }

        if let closeTitle = session?.translate(key: Constants.kCloseText.rawValue, formatParams: [:]), !closeTitle.isEmpty {
            closeButton.buttonTitle = closeTitle
        }

        overrideAssets(delegate: session?.delegate)
    }
    
    private func overrideAssets(delegate: NINChatSessionInternalDelegate?) {
        closeButton.overrideAssets(with: delegate)
        
        if let placeholder = delegate?.override(colorAsset: .ninchatColorTitlebarPlaceholder) {
            agentInfoPlaceholder.backgroundColor = placeholder
            if agentAvatarImageView.isHidden { agentAvatarContainer.backgroundColor = placeholder }
        }
    }
}
