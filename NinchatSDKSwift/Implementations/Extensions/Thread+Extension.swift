//
// Copyright (c) 19/08/2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

extension Thread {
    /// Taken from `https://stackoverflow.com/a/59732115/7264553`
    var isRunningXCTests: Bool {
        let allKeys = self.threadDictionary.allKeys
        let stringKeys = allKeys.compactMap({ $0 as? String })
        let hasXCTestContextKey = stringKeys.contains("kXCTContextStackThreadKey")
        let hasXCTestSubstring = stringKeys.contains(where: { $0.split(separator: ".").contains("xctest") })
        return hasXCTestContextKey || hasXCTestSubstring
    }
}
