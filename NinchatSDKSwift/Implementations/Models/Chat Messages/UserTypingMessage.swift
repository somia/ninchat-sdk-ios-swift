//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct UserTypingMessage: ChatMessage, Equatable {
    // MARK: - ChatMessage
    let timestamp: Date
    let messageID: String

    // MARK: - UserTypingMessage
    let user: ChannelUser

    init(timestamp: Date, messageID: String?, user: ChannelUser) {
        self.timestamp = timestamp
        self.messageID = (messageID ?? "0") + "_1"
        self.user = user
    }
}

// MARK: - Equatable
extension UserTypingMessage {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.messageID == rhs.messageID
    }
}