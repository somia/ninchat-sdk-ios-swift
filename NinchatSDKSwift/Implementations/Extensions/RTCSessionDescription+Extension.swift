//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatWebRTC

extension RTCSessionDescription {
    var toDictionary: [String:String] {
        [Constants.RTCSessionDescriptionType.rawValue: RTCSessionDescription.string(for: self.type), Constants.RTCSessionDescriptionSDP.rawValue: self.sdp]
    }
}
