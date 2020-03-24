//
// Copyright (c) 13.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension UIButton {
    @discardableResult
    func roundCorners() -> UIButton {
        self.layer.cornerRadius = self.bounds.height / 2
        return self
    }
}
