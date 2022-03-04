//
// Copyright (c) 20.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class QuestionnaireCell: UITableViewCell {
    @IBOutlet private(set) weak var conversationContentView: UIStackView!
    
    @IBOutlet private(set) weak var conversationContentViewStyle: UIImageView!      /// bubble image
    @IBOutlet private(set) weak var conversationTitleContentView: UIView!           /// title text is added to this
    @IBOutlet private(set) weak var conversationTitleContainerView: UIView!         /// title is added to this
    @IBOutlet private(set) weak var conversationOptionsContainerView: UIView!       /// elements are added to this
    
    @IBOutlet private(set) weak var leftAvatarContainerView: UIView!
    @IBOutlet private(set) var conversationAuthorView: [Any]!
    

    var indexPath: IndexPath!
    var style: QuestionnaireStyle!
    weak var sessionManager: NINChatSessionManager?
    
    private lazy var usernameLabel: UILabel? = {
        self.conversationAuthorView.first(where: { $0 is UILabel }) as? UILabel
    }()
    private lazy var userAvatarImageView: UIImageView? = {
        self.conversationAuthorView.first(where: { $0 is UIImageView }) as? UIImageView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        guard style == .conversation else { return }
        self.conversationTitleContainerView?.viewWithTag(1)?.removeFromSuperview()
        self.conversationTitleContainerView?.isHidden = true
        self.conversationOptionsContainerView?.viewWithTag(1)?.removeFromSuperview()
        self.conversationOptionsContainerView?.isHidden = true
    }

    func addElement(_ element: QuestionnaireElement) {
        switch style {
        case .form:
            self.contentView.addSubview(element)
            self.layoutForm(element)
            
        case .conversation:
            conversationContentViewStyle.image = UIImage(named: (indexPath.row == 0) ? "chat_bubble_left" : "chat_bubble_left_series", in: .SDKBundle, compatibleWith: nil)
            setupTitles(usernameLabel)
            setupAvatar(userAvatarImageView)

            if let title = element as? HasTitle {
                title.titleView.tag = 1
                self.layoutTitle(title.titleView, element: element)
            }
            if let options = element as? HasOptions {
                options.optionsView.tag = 1
                self.layoutOptions(options.optionsView)
            }
        case .none:
            fatalError("style cannot be none")
        }
    }
    
    func hideUserNameAndAvatar(_ hide: Bool) {
        self.usernameLabel?.isHidden = hide
        self.userAvatarImageView?.isHidden = hide
        
        self.conversationContentView.top?.constant = (hide) ? 0 : 55
    }

    private func setupTitles(_ usernameLabel: UILabel?) {
        guard let usernameLabel = usernameLabel else { return }
        
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

    private func setupAvatar(_ userAvatar: UIImageView?) {
        guard let userAvatar = userAvatar else { return }
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
    
    private func layoutForm(_ view: UIView) {
        view.fix(leading: (4.0, self.contentView), trailing: (4.0, self.contentView))
    }
    
    private func layoutTitle(_ view: UIView, element: QuestionnaireElement) {
        self.conversationTitleContainerView.isHidden = (element.elementConfiguration?.label ?? "").isEmpty
        self.conversationTitleContainerView.viewWithTag(1)?.removeFromSuperview()
        self.conversationTitleContainerView.addSubview(view)
        
        view
            .fix(top: (4.0, self.conversationTitleContainerView), bottom: (4.0, self.conversationTitleContainerView))
    }
    
    private func layoutOptions(_ view: UIView) {
        self.conversationOptionsContainerView.isHidden = false
        self.conversationOptionsContainerView.viewWithTag(1)?.removeFromSuperview()
        self.conversationOptionsContainerView.addSubview(view)
        
        view
            .fix(top: (4.0, self.conversationOptionsContainerView), bottom: (4.0, self.conversationOptionsContainerView))
    }
}

class QuestionnaireCellConversation: QuestionnaireCell {}
class QuestionnaireCellForm: QuestionnaireCell {}
