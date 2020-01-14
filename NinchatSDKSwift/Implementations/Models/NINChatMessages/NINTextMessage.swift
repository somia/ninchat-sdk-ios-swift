//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

final class NINTextMessage: NSObject, NINChannelMessage {
    internal var messageID: String!
    internal var mine: Bool
    var sender: NINChannelUser!
    var textContent: String?
    var timestamp: Date!
    var attachment: NINFileInfo?
    
    /**
        * YES if this message is a part in a series, ie. the sender of the previous message
        * also sent this message.
    */
    var series: Bool = false
    
    init(messageID: String, textContent: String?, sender: NINChannelUser, timestamp: Date, mine: Bool, attachment: NINFileInfo?) {
        self.messageID = messageID
        self.textContent = textContent
        self.sender = sender
        self.timestamp = timestamp
        self.mine = mine
        self.attachment = attachment
    }
}
