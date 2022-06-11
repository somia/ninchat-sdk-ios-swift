//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatWebRTC

extension RTCIceCandidate {
    var toDictionary: [String:Any?] {
        [Constants.RTCIceCandidateKeyCandidate.rawValue: self.sdp, Constants.RTCIceCandidateSDPMLineIndex.rawValue: self.sdpMLineIndex, Constants.RTCIceCandidateSDPMid.rawValue: self.sdpMid]
    }
}
