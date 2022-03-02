//
// Copyright (c) 20.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class QuestionnaireCell: UITableViewCell {
    @IBOutlet private(set) weak var conversationView: UIView!
    @IBOutlet private(set) weak var conversationContentView: UIStackView!
    
    @IBOutlet private(set) weak var conversationContentViewStyle: UIImageView!      /// bubble image
    @IBOutlet private(set) weak var conversationTitleContentView: UIView!           /// title text is added to this
    @IBOutlet private(set) weak var conversationTitleContainerView: UIView!         /// title is added to this
    @IBOutlet private(set) weak var conversationOptionsContainerView: UIView!       /// elements are added to this
    
    @IBOutlet private(set) weak var formContentView: UIView!
    
    @IBOutlet private(set) weak var leftAvatarContainerView: UIView!
    @IBOutlet private(set) var conversationAuthorView: [Any]!
    

    var indexPath: IndexPath! {
        didSet {
            self.conversationContentViewStyle.image = UIImage(named: (indexPath.row == 0) ? "chat_bubble_left" : "chat_bubble_left_series", in: .SDKBundle, compatibleWith: nil)
            self.conversationAuthorView.compactMap({ $0 as? UIView }).forEach({ $0.isHidden = (indexPath.row != 0) })
            self.conversationContentView.top?.constant = (indexPath.row == 0) ? 55 : 0
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
        self.conversationAuthorView.first(where: { $0 is UILabel }) as? UILabel
    }()
    private lazy var userAvatarImageView: UIImageView? = {
        self.conversationAuthorView.first(where: { $0 is UIImageView }) as? UIImageView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()

        self.conversationOptionsContainerView.subviews.forEach({ $0.removeFromSuperview() })
        self.conversationTitleContentView.subviews.forEach({ $0.removeFromSuperview() })
        self.formContentView.subviews.forEach({ $0.removeFromSuperview() })
    }

    func addElement(_ element: QuestionnaireElement) {
        switch style {
        case .form:
            conversationOptionsContainerView.isHidden = true
            formContentView.isHidden = false            
            formContentView.addSubview(element)
        case .conversation:
            conversationOptionsContainerView.isHidden = false
            formContentView.isHidden = true
            
            if let title = element as? HasTitle {
                self.layoutTitle(title.titleView)
            }
            if let options = element as? HasOptions {
                self.layoutOptions(options.optionsView)
            }
            
            self.conversationTitleContainerView.isHidden = (element.elementConfiguration?.label ?? "").isEmpty
        case .none:
            fatalError("style cannot be none")
        }
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
        
        if let layer = delegate.override(layerAsset: .ninchatBubbleQuestionnaire) {
            conversationTitleContainerView.layer.apply(layer, force: false)
            conversationContentViewStyle.isHidden = true
        } else if let backgroundColor = delegate.override(questionnaireAsset: .ninchatQuestionnaireColorBubble) {
            conversationContentViewStyle.tintColor = backgroundColor
            conversationContentViewStyle.isHidden = false
        }
    }

    private func setupAvatar(_ userAvatar: UIImageView) {
        let avatar = AvatarConfig(forQuestionnaire: self.sessionManager)

        userAvatar.isHidden = !avatar.show
        userAvatar.round()
        userAvatar.contentMode = .scaleAspectFill
        leftAvatarContainerView.width?.constant = (userAvatar.isHidden) ? 0 : 35
        
        let defaultImage = UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)!
        if let url = avatar.imageOverrideURL, !url.isEmpty {
            userAvatar.image(from: url, defaultImage: defaultImage)
        } else {
            userAvatar.image = defaultImage
        }
    }
    
    private func layoutTitle(_ view: UIView) {
        self.conversationTitleContainerView.addSubview(view)
        
        view
            .fix(top: (4.0, self.conversationTitleContainerView), bottom: (4.0, self.conversationTitleContainerView))
    }
    
    private func layoutOptions(_ view: UIView) {
        self.conversationOptionsContainerView.addSubview(view)
        
        view
            .fix(top: (4.0, self.conversationOptionsContainerView), bottom: (4.0, self.conversationOptionsContainerView))
    }
}
