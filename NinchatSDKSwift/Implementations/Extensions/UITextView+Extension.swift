//
// Copyright (c) 22.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AutoLayoutSwift

extension UITextView {
    func updateSize(to height: CGFloat) {
        guard let constraints = self.find(attribute: .height), constraints.constant != height else { return }

        constraints.constant = height
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func newSize(maxHeight: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        let newHeight = ceil(self.sizeThatFits(CGSize(width: self.bounds.width, height: .greatestFiniteMagnitude)).height)
        return min(newHeight, maxHeight)
    }
    
    func setAttributed(text: String, font: UIFont?, color: UIColor? = nil, width: CGFloat? = nil) {
        if text.containsTags {
            self.attributedText = text.htmlAttributedString(withFont: font, alignment: self.textAlignment, color: color ?? self.textColor, width: width)
        } else {
            self.setPlain(text: text, font: font)
        }
    }
    
    func setPlain(text: String, font: UIFont?) {
        self.attributedText = text.plainString(withFont: font, alignment: self.textAlignment, color: self.textColor)
    }
}
