//
// Copyright (c) 14/07/2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

public extension NINLowLevelClientProps {
    var ninchatError: NinchatError? {
        let errorType: NINResult<String> = self.get(forKey: "error_type")
        if case let .success(error) = errorType {
            return NinchatError(type: error, props: self)
        }
        return nil
    }
}

public struct NinchatError: Error {
    public var type: String = "type_not_specified"
    public var reason, sessionID, actionID, userID, identityType, identityName, channelID, realmID, queueID, tagID, messageType: String?

    init(type: String, props: NINLowLevelClientProps?) {
        self.type = type

        /// Initial optional properties
        guard let props = props else { return }

        let errorReason: NINResult<String> = props.get(forKey: "error_reason")
        if case let .success(reason) = errorReason { self.reason = reason }

        let sessionID: NINResult<String> = props.get(forKey: "session_id")
        if case let .success(id) = sessionID { self.sessionID = id }

        let actionID: NINResult<String> = props.get(forKey: "action_id")
        if case let .success(id) = actionID { self.actionID = id }

        let userID: NINResult<String> = props.get(forKey: "user_id")
        if case let .success(id) = userID { self.userID = id  }

        let identityType: NINResult<String> = props.get(forKey: "identity_type")
        if case let .success(type) = identityType { self.identityType = type }

        let identityName: NINResult<String> = props.get(forKey: "identity_name")
        if case let .success(name) = identityName { self.identityName = name }

        let channelID: NINResult<String> = props.get(forKey: "channel_id")
        if case let .success(id) = channelID { self.channelID = id }

        let realmID: NINResult<String> = props.get(forKey: "realm_id")
        if case let .success(id) = realmID { self.realmID = id }

        let queueID: NINResult<String> = props.get(forKey: "queue_id")
        if case let .success(id) = queueID { self.queueID = id }

        let tagID: NINResult<String> = props.get(forKey: "tag_id")
        if case let .success(id) = tagID { self.tagID = id }

        let messageType: NINResult<String> = props.get(forKey: "message_type")
        if case let .success(type) = messageType { self.messageType = type }
    }
}
