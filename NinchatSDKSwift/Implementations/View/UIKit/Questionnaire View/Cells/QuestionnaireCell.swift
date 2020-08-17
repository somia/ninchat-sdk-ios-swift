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
    @IBOutlet private(set) var conversationDetailsView: [Any]!
    @IBOutlet private(set) weak var formContentView: UIView!

    var content: UIView {
        style == .conversation ? self.conversationContentView : self.formContentView
    }

    var indexPath: IndexPath! {
        didSet {
            self.conversationContentViewStyle.image = UIImage(named: (indexPath.row == 0) ? "chat_bubble_left" : "chat_bubble_left_series", in: .SDKBundle, compatibleWith: nil)
            self.conversationDetailsView.compactMap({ $0 as? UIView }).forEach({ $0.isHidden = (indexPath.row != 0) })
            self.conversationDetailsView.compactMap({ $0 as? NSLayoutConstraint }).forEach({ $0.constant = (indexPath.row == 0) ? 40 : 0 })
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
                  let usernameLabel = self.conversationDetailsView.compactMap({ $0 as? UILabel }).first,
                  let userAvatar = self.conversationDetailsView.compactMap({ $0 as? UIImageView }).first
                else { return }

            usernameLabel.text = sessionManager?.siteConfiguration.audienceQuestionnaireUserName ?? ""
            if let avatar = sessionManager?.siteConfiguration.audienceQuestionnaireAvatar as? String, !avatar.isEmpty {
                userAvatar.image(from: avatar)
            } else {
                userAvatar.image = UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)
            }
        }
    }
}
