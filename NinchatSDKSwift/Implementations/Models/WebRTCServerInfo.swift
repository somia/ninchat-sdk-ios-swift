//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatWebRTC

struct WebRTCServerInfo {
    let url: String
    let username: String?
    let credential: String?
    
    var iceServer: RTCIceServer! {
        RTCIceServer(urlStrings: [self.url], username: self.username ?? "", credential: self.credential ?? "")
    }
    var description: String {
        "WebRTC server url: \(self.url)"
    }
}
