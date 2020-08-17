//
// Copyright (c) 4.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct debugger {
    @discardableResult
    init(_ value: String, isDebugOnly: Bool = true) {
        if isDebugOnly {
            #if DEBUG
            print(value)
            #endif
        } else {
            print(value)
        }
    }

    static func error(_ error: NinchatError?, isDebugOnly: Bool = true) {
        guard let error = error else { return }

        func output() {
            var log = "error_type: \(error.type)"
            if let reason = error.reason, !reason.isEmpty { log += ",   error_reason: \(reason)" }
            if let sessionID = error.sessionID, !sessionID.isEmpty { log += ",   session_id: \(sessionID)" }
            if let actionID = error.actionID, !actionID.isEmpty { log += ",   action_id: \(actionID)" }
            if let userID = error.userID, !userID.isEmpty { log += ",   user_id: \(userID)" }
            if let identityType = error.identityType, !identityType.isEmpty { log += ",   identity_type: \(identityType)" }
            if let identityName = error.identityName, !identityName.isEmpty { log += ",   identity_name: \(identityName)" }
            if let channelID = error.channelID, !channelID.isEmpty { log += ",   channel_id: \(channelID)" }
            if let realmID = error.realmID, !realmID.isEmpty { log += ",   realm_id: \(realmID)" }
            if let queueID = error.queueID, !queueID.isEmpty { log += ",   queue_id: \(queueID)" }
            if let tagID = error.tagID, !tagID.isEmpty { log += ",   tag_id: \(tagID)" }
            if let messageType = error.messageType, !messageType.isEmpty { log += ",   tag_id: \(messageType)" }
            print(log)
        }

        if isDebugOnly {
            #if DEBUG
            output()
            #endif
        } else {
            output()
        }
    }
}
