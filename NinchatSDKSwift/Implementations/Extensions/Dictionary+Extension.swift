//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import AnyCodable
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
        guard let lineIndex = self[Constants.RTCIceCandidateSDPMLineIndex.rawValue] as? String else {
            debugger("** ERROR: missing '\(Constants.RTCIceCandidateSDPMLineIndex.rawValue)' key in dictionary for RTCIceCandidate"); return nil
        }
        
        return RTCIceCandidate(sdp: candidate, sdpMLineIndex: Int32(lineIndex)!, sdpMid: self[Constants.RTCIceCandidateSDPMid.rawValue] as? String)
    }

    func filter(based keys: [String]) -> Dictionary {
        self.filter({ keys.contains($0.key) })
    }
}

extension Dictionary where Key==String, Value==AnyHashable {
    func filter<T:Equatable>(based dictionary: [String:T], keys: [String]) -> Self? {
        guard dictionary.keys.count > 0, self.keys.count > 0 else { return nil }
        let result = self.filter(based: keys).filter { (key, value) in
            let dictValue: AnyHashable? = (dictionary[key] is AnyCodable) ? ((dictionary[key] as? AnyCodable)?.value as? AnyHashable) : dictionary[key] as? AnyHashable
            let selfValue: AnyHashable? = (value is AnyCodable) ? ((value as? AnyCodable)?.value as? AnyHashable) : value

            if let strValue = selfValue as? String, let regexPattern = dictValue as? String, let regexResult = strValue.extractRegex(withPattern: regexPattern), regexResult.count > 0 {
                return true
            }
            return dictValue == selfValue
        }

        return (result.count > 0) ? result : nil
    }
}

extension Dictionary where Key==String {
    func find<T>(_ key: String) -> [T] {
        var keys: [T] = []
        
        if let value = self[key] as? T {
            keys.append(value)
        }
        self.values.compactMap({ $0 as? [String:Any] }).forEach({
            keys.append(contentsOf: $0.find(key))
        })
        
        return keys
    }
}
