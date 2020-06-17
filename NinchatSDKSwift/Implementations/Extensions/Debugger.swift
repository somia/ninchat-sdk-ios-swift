//
// Copyright (c) 4.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct debugger {
    @discardableResult
    init(_ value: String, isDebugOnly: Bool = true) {
        if isDebugOnly {
            #if DEBUG
            print(value)
            #endif
        } else {
            print(value)
        }
    }
}
