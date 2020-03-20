//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct TextMessage: ChannelMessage, Equatable {
    // MARK: - ChatMessage
    let timestamp: Date
    
    // MARK: - ChannelMessage
    let messageID: String
    let mine: Bool
    let sender: ChannelUser
    var series: Bool = false
    
    // MARK: - TextMessage
    let textContent: String?
    let attachment: FileInfo?
    
    // MARK: - Equatable
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.messageID == rhs.messageID
    }
}
