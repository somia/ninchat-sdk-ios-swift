//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct MetaMessage: ChatMessage, Equatable {
    // MARK: - ChatMessage
    let timestamp: Date
    
    // MARK: - MetaMessage
    let text: String
    let closeChatButtonTitle: String?
}

// MARK: - Equatable
extension MetaMessage {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.text == rhs.text
    }
}