//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import AnyCodable

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

final class RTCSignal: Codable {
    let candidate: [String:String]?
    let sdp: [String:String]?
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        candidate = try container.decodeIfPresent([String:AnyCodable].self, forKey: .candidate)?.reduce(into: [:]) { (dic: inout [String:String], item) in
            dic[item.key] = String(describing: "\(item.value)")
        }
        sdp = try container.decodeIfPresent([String:String].self, forKey: .sdp)
    }
    
    init(candidate: [String:String]?, sdp: [String:String]?) {
        self.candidate = candidate
        self.sdp = sdp
    }
    
    enum CodingKeys: String, CodingKey {
        case candidate, sdp
    }
}

