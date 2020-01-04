//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

extension NINLowLevelClientSession {
    func send(_ param: NINLowLevelClientProps) throws -> Int {
        var actionID: Int64 = 0
        try self.send(param, payload: nil, actionId: &actionID)
        
        return Int(actionID)
    }
}
