//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct MetaMessage: ChatMessage, Equatable {
    // MARK: - ChatMessage
    let timestamp: Date
    let messageID: String

    // MARK: - MetaMessage
    let text: String
    let closeChatButtonTitle: String?

    init(timestamp: Date, messageID: String?, text: String, closeChatButtonTitle: String?) {
        self.timestamp = timestamp
        self.messageID = (messageID ?? "0") + "_1"
        self.text = text
        self.closeChatButtonTitle = closeChatButtonTitle
    }
}

// MARK: - Equatable
extension MetaMessage {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.messageID == rhs.messageID
    }
}