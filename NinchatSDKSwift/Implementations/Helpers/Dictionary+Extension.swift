//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import WebRTC

extension Dictionary where Key==AnyHashable {
    var toData: Data? {
        try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}

extension Dictionary where Key==String {
    var toRTCSessionDescription: RTCSessionDescription? {
        guard let type = self[Constants.RTCSessionDescriptionType.rawValue] as? String,
              let sdp = self[Constants.RTCSessionDescriptionSDP.rawValue] as? String
            else {
            debugger("** ERROR: Constructing RTCSessionDescription from incomplete or invalid data"); return nil
        }
        
        return RTCSessionDescription(type: RTCSessionDescription.type(for: type), sdp: sdp)
    }
    
    var toRTCIceCandidate: RTCIceCandidate? {
        guard let candidate = self[Constants.RTCIceCandidateKeyCandidate.rawValue] as? String else {
            debugger("** ERROR: missing '\(Constants.RTCIceCandidateKeyCandidate.rawValue)' key in dictionary for RTCIceCandidate"); return nil
        }
        guard let lineIndex = self[Constants.RTCIceCandidateSDPMLineIndex.rawValue] as? Int32 else {
            debugger("** ERROR: missing '\(Constants.RTCIceCandidateSDPMLineIndex.rawValue)' key in dictionary for RTCIceCandidate"); return nil
        }
        
        return RTCIceCandidate(sdp: candidate, sdpMLineIndex: lineIndex, sdpMid: self[Constants.RTCIceCandidateSDPMid.rawValue] as? String)
    }
}