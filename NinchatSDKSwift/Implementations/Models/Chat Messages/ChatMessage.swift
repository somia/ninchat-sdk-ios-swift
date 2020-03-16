//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol ChatMessage {
    /** Message timestamp. */
    var timestamp: Date { get }
    
    var asEquatable: ChatMessageStruct { get }
}

extension ChatMessage where Self: Equatable {
    var asEquatable: ChatMessageStruct {
        ChatMessageStruct(chatMessage: self)
    }
}

struct ChatMessageStruct: ChatMessage, Equatable {
    var timestamp: Date { chatMessage.timestamp }
    private let chatMessage: ChatMessage
    
    init(chatMessage: ChatMessage) {
        self.chatMessage = chatMessage
    }
    
    static func == (lhs: ChatMessageStruct, rhs: ChatMessageStruct) -> Bool {
        lhs.timestamp == rhs.timestamp
    }
}