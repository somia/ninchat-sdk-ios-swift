//
// Copyright (c) 31.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import NinchatLowLevelClient

extension NINLowLevelClientPayload {
    /// For some unknown reasons, the `NINLowLevelClientPayload` initialization is optional
    /// The following variable unwrap it
    static var initiate: NINLowLevelClientPayload {
        NINLowLevelClientPayload()!
    }
}
