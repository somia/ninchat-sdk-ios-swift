//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

extension NINLowLevelClientSession {
    func send(_ param: NINLowLevelClientProps, _ payload: NINLowLevelClientPayload? = nil) throws -> Int {
        var actionID: Int64 = 0
        try self.send(param, payload: payload, actionId: &actionID)
        
        return Int(actionID)
    }
}
