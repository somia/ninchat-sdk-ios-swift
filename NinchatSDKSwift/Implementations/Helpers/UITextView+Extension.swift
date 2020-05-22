//
// Copyright (c) 22.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AutoLayoutSwift

extension UITextView {
    func updateSize(to height: CGFloat) {
        self.find(attribute: .height)?.constant = height
        
        self.superview?.setNeedsLayout()
        self.superview?.layoutIfNeeded()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func newSize(maxHeight: CGFloat = 9999) -> CGFloat {
        let newHeight = ceil(self.sizeThatFits(CGSize(width: self.bounds.width, height: 9999)).height)
        return min(newHeight, maxHeight)
    }
    
    func setAttributed(text: String, font: UIFont?, color: UIColor? = nil) {
        if text.containsTags {
            self.attributedText = text.replacingOccurrences(of: "ä", with: "ä")
                                        .replacingOccurrences(of: "ö", with: "ö")
                                        .replacingOccurrences(of: "å", with: "å")
                                        .htmlAttributedString(withFont: font, alignment: self.textAlignment, color: color ?? self.textColor)
        } else {
            self.setPlain(text: text, font: font)
        }
    }
    
    func setPlain(text: String, font: UIFont?) {
        self.attributedText = text.plainString(withFont: font, alignment: self.textAlignment, color: self.textColor)
    }
}
