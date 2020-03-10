//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

extension NINLowLevelClientSession {
    func send(_ param: NINLowLevelClientProps, _ payload: NINLowLevelClientPayload? = nil) throws -> Int? {
        var actionID = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        try self.send(param, payload: payload, actionId: actionID)
        
        defer {
            actionID.deallocate()
        }
        return Int(actionID.pointee)
    }
}
