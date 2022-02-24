//
// Copyright (c) 20.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class QuestionnaireCell: UITableViewCell {
    @IBOutlet private(set) weak var conversationView: UIView!
    @IBOutlet private(set) weak var conversationContentView: UIView!
    @IBOutlet private(set) weak var conversationContentViewStyle: UIImageView!
    @IBOutlet private(set) weak var leftAvatarContainerView: UIView!
    @IBOutlet private(set) var conversationDetailsView: [Any]!
    @IBOutlet private(set) weak var formContentView: UIView!

    var content: UIView {
        style == .conversation ? self.conversationContentView : self.formContentView
    }

    var indexPath: IndexPath! {
        didSet {
            self.conversationContentViewStyle.image = UIImage(named: (indexPath.row == 0) ? "chat_bubble_left" : "chat_bubble_left_series", in: .SDKBundle, compatibleWith: nil)
            self.conversationDetailsView.compactMap({ $0 as? UIView }).forEach({ $0.isHidden = (indexPath.row != 0) })
            self.conversationContentViewStyle.top?.constant = (indexPath.row == 0) ? 55 : 0
        }
    }

    var style: QuestionnaireStyle! {
        didSet {
            self.conversationView.isHidden = (style == .form)
            self.formContentView.isHidden = !self.conversationView.isHidden
        }
    }

    weak var sessionManager: NINChatSessionManager? {
        didSet {
            guard self.style == .conversation,
                let usernameLabel = self.usernameLabel,
                let userAvatar = self.userAvatarImageView
            else { return }

            setupTitles(usernameLabel)
            setupAvatar(userAvatar)
        }
    }

    private lazy var usernameLabel: UILabel? = {
        self.conversationDetailsView.first(where: { $0 is UILabel }) as? UILabel
    }()
    private lazy var userAvatarImageView: UIImageView? = {
        self.conversationDetailsView.first(where: { $0 is UIImageView }) as? UIImageView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()

        self.content.subviews.forEach({ $0.removeFromSuperview() })
    }

    func hideUserNameAndAvatar(_ bool: Bool) {
        self.usernameLabel?.isHidden = bool
        self.userAvatarImageView?.isHidden = bool
    }

    private func setupTitles(_ usernameLabel: UILabel) {
        usernameLabel.text = sessionManager?.siteConfiguration.audienceQuestionnaireUserName ?? ""
        usernameLabel.font = .ninchat
        
        guard let delegate = sessionManager?.delegate else { return }
        if let usernameColor = delegate.override(colorAsset: .ninchatColorChatName) {
            usernameLabel.textColor = usernameColor
        }
        if let backgroundColor = delegate.override(questionnaireAsset: .ninchatQuestionnaireColorBubble) {
            conversationContentViewStyle.tintColor = backgroundColor
        }
    }

    private func setupAvatar(_ userAvatar: UIImageView) {
        let avatar = AvatarConfig(forQuestionnaire: self.sessionManager)

        userAvatar.isHidden = !avatar.show
        leftAvatarContainerView.width?.constant = (userAvatar.isHidden) ? 0 : 35
        
        let defaultImage = UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)!
        if let url = avatar.imageOverrideURL, !url.isEmpty {
            userAvatar.image(from: url, defaultImage: defaultImage)
        } else {
            userAvatar.image = defaultImage
        }
    }
}
