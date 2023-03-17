//
// Copyright (c) 14.2.2023 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class JoinVideoButton: NINButton {
    override var isEnabled: Bool {
        didSet {
            if self.isEnabled {
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(1.0)
            } else {
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.5)
            }
        }
    }
}
