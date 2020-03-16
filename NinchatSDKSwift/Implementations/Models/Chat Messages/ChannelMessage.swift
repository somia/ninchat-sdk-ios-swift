//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol ChannelMessage: ChatMessage {
    /** Message ID. */
    var messageID: String { get }
    
    /** Whether this message is sent by the mobile user (this device). */
    var mine: Bool { get }
    
    /**
    * YES if this message is a part in a series, ie. the sender of the previous message
    * also sent this message.
    */
    var series: Bool { get set }
    
    /** The message sender. */
    var sender: ChannelUser { get }
}