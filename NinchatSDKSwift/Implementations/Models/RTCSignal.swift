//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum MessageType: String, Decodable {
    case candidate = "ninchat.com/rtc/ice-candidate"
    case answer = "ninchat.com/rtc/answer"
    case offer = "ninchat.com/rtc/offer"
    case call = "ninchat.com/rtc/call"
    case pickup = "ninchat.com/rtc/pick-up"
    case hangup = "ninchat.com/rtc/hang-up"
    case text = "ninchat.com/text"
    case file = "ninchat.com/file"
    case compose = "ninchat.com/ui/compose"
    case channel = "ninchat.com/info/channel"
    case part = "ninchat.com/info/part"
    case metadata = "ninchat.com/metadata"
    case uiAction = "ninchat.com/ui/action"
    
    var isRTC: Bool {
        return self.rawValue.hasPrefix("ninchat.com/rtc/")
    }
}

struct RTCSignal: Decodable {
    let candidate: [String:String]
    let sdp: [String:String]
    
    enum CodingKeys: String, CodingKey {
        case candidate, sdp
    }
}
