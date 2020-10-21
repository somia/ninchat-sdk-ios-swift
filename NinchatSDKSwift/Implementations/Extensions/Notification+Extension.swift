//
// Copyright (c) 21.10.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

extension Notification {
    ///
    /// - Returns: KeyboardFrameBeginUserInfoKey, KeyboardFrameEndUserInfoKey, KeyboardAnimationDurationUserInfoKey
    var keyboardInfo: (beginSize: CGRect?, endSize: CGRect?, animDuration: TimeInterval?) {
        (
                (self.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
                (self.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                self.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        )
    }
}
