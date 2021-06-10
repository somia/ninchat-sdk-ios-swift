//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct AvatarConfig {
    let imageOverrideURL: String?
    let nameOverride: String
    var show: Bool!

    init(session: NINChatSessionManager?) {
        self.imageOverrideURL = session?.siteConfiguration.audienceQuestionnaireAvatar as? String
        self.nameOverride = session?.siteConfiguration.audienceQuestionnaireUserName ?? ""
        self.show = avatarVisibilityRules(session)
    }
}

extension AvatarConfig {
    /// Rules based on `https://github.com/somia/mobile/issues/343#issuecomment-857721302`
    private func avatarVisibilityRules(_ session: NINChatSessionManager?) -> Bool {
        guard let session = session else {
            return false
        }

        /// 1- If titlebar is shown, agentAvatar is not shown ever in questionnaire or on backlog
        if !session.siteConfiguration.hideTitlebar {
            return false
        }

        /// 2- If agentAvatar: false, it's not shown anywhere
        if let avatarBool = session.siteConfiguration.agentAvatar as? Bool, !avatarBool {
            return false
        }

        /// 3- agentAvatar:true, show user_attrs.iconurl everywhere
        /// 4- agentAvatar:url, show that instead
        /// 5- no iconurl/agentAvatar, use avatar-male default icon
        /// 6- no questionnaireAvatar, use gray placeholder ball and block
        return true
    }
}
