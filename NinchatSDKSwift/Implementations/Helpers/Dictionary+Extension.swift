//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

extension Dictionary where Key==AnyHashable {
    var toData: Data? {
        try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}