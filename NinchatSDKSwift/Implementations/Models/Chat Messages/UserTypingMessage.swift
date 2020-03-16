//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct UserTypingMessage: ChatMessage, Equatable {
    // MARK: - ChatMessage
    let timestamp: Date
    
    // MARK: - UserTypingMessage
    let user: ChannelUser
}

// MARK: - Equatable
extension UserTypingMessage {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.user == rhs.user
    }
}