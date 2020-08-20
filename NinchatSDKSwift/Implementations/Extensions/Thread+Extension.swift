//
// Copyright (c) 19/08/2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

extension Thread {
    /// Taken from `https://stackoverflow.com/a/59732115/7264553`
    var isRunningXCTests: Bool {
        self.threadDictionary.allKeys.compactMap({ $0 as? String }).filter({ $0.split(separator: ".").contains("xctest") }).count > 0
    }
}
