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
            print("""
                  error log:
                  error_type: \(error.type),
                  error_reason: \(error.reason ?? "null"),
                  session_id: \(error.sessionID ?? "null"),
                  action_id: \(error.actionID ?? "null"),
                  user_id: \(error.userID ?? "null"),
                  identity_type: \(error.identityType ?? "null"),
                  identity_name: \(error.identityName ?? "null"),
                  channel_id: \(error.channelID ?? "null"),
                  realm_id: \(error.realmID ?? "null"),
                  queue_id: \(error.queueID ?? "null"),
                  tag_id: \(error.tagID ?? "null"),
                  message_type: \(error.messageType ?? "null"),
                  """)
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
