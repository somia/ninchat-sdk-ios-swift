//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

struct InboundMessage: Equatable {
    let params: NINLowLevelClientProps
    let payload: NINLowLevelClientPayload
    let created: Date
    let messageID: String
    
    init(params: NINLowLevelClientProps, payload: NINLowLevelClientPayload) {
        self.params = params
        self.payload = payload
        self.created = Date()
        self.messageID = params.messageID.value
    }
    
    static func ==(lhs: InboundMessage, rhs: InboundMessage) -> Bool {
        lhs.messageID == rhs.messageID
    }
}