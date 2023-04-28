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
    @IBOutlet private(set) weak var agentAvatarImageView: UIImageView! {
        didSet {
            agentAvatarImageView.contentMode = .scaleAspectFill
        }
    }
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
    
    func setupView(_ session: NINChatSessionManager?, _ showAvatar: Bool? = nil, collapseCloseButton: Bool, view: HasTitleBar, defaultAvatarView: HasDefaultAvatar?) {
        self.setupName(view)
        self.setupJob(view)
        
        self.agentAvatarContainer.isHidden = self.setupAvatarContainer(session, showAvatar: showAvatar)
        if !agentAvatarContainer.isHidden {
            self.setupAvatar(view, defaultAvatar: defaultAvatarView?.defaultAvatar)
        }
        
        self.setupCloseButton(session, collapse: collapseCloseButton)
        overrideAssets(delegate: session?.delegate)
    }
    
    private func overrideAssets(delegate: NINChatSessionInternalDelegate?) {
        closeButton.overrideAssets(with: delegate, in: .titlebar)
        
        if let placeholder = delegate?.override(colorAsset: .ninchatColorTitlebarPlaceholder) {
            agentInfoPlaceholder.backgroundColor = placeholder
            if agentAvatarImageView.isHidden { agentAvatarContainer.backgroundColor = placeholder }
        }
    }
}

private extension Titlebar {
    private func setupName(_ view: HasTitleBar) {
        if let name = view.titlebarName, !name.isEmpty {
            /// show titlebar
            agentInfoPlaceholder.isHidden = true
            agentNameLabel.text = name
        } else {
            /// show placeholder
            agentInfoStackView.isHidden = true
        }
    }
    
    private func setupJob(_ view: HasTitleBar) {
        if let job = view.titlebarJob, !job.isEmpty {
            agentJobLabel.text = job
        } else {
            /// Hide job if not available
            agentJobLabel.isHidden = true
        }
    }
    
    private func setupAvatarContainer(_ session: NINChatSessionManager?, showAvatar: Bool?) -> Bool {
        /// Show/Hide avatar
        if agentInfoStackView.isHidden {
            /// show placeholder if name is hidden
            return true
        } else if let showAvatar = showAvatar {
            /// set the avatar status explicitly
            return !showAvatar
        } else if let agentAvatar = session?.siteConfiguration.agentAvatar as? Bool, !agentAvatar {
            /// don't show avatar if config.agentAvatar = false
            return true
        }
        return true
    }
    
    private func setupAvatar(_ view: HasTitleBar, defaultAvatar: UIImage?) {
        /// Set Avatar
        if let avatarImage = view.titlebarAvatar, !avatarImage.isEmpty {
            agentAvatarContainer.backgroundColor = .white
            agentAvatarImageView.image(from: avatarImage, defaultImage: defaultAvatar ?? UIImage())
        } else if let defaultAvatar = defaultAvatar {
            agentAvatarContainer.backgroundColor = .white
            agentAvatarImageView.image = defaultAvatar
        }
    }
    
    private func setupCloseButton(_ session: NINChatSessionManager?, collapse: Bool) {
        closeButton.buttonTitle = session?.translate(key: Constants.kCloseText.rawValue, formatParams: [:]) ?? ""
        
        guard let session = session else { return }
        let isHidden = collapse || session.siteConfiguration.hideTitlebar
        closeButton.isHidden = isHidden
        // button can be hidden by siteConfiguration but still keep its width for backward compatibility with older views,
        // however we're using our own close button for group video call and hence this one shouldn't even take extra space.
        closeButton.widthAnchor.constraint(equalToConstant: collapse ? 0 : 122).isActive = true
    }
}
