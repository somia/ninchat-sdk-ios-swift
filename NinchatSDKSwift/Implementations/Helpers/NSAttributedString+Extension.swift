//
// Copyright (c) 25.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import Foundation

extension NSAttributedString {
    func boundSize(maxSize: CGSize) -> CGSize {
        self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral.size
    }
}