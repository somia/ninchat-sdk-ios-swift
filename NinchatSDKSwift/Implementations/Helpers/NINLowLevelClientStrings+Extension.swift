//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

extension NINLowLevelClientStrings {
    /// For some unknown reasons, the `NINLowLevelClientStrings` initialization is optional
    /// The following variable unwrap it
    static var initiate: NINLowLevelClientStrings {
        return NINLowLevelClientStrings()!
    }
}
