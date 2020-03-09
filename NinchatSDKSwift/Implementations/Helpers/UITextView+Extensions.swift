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
    
    func setPlain(text: String, font: UIFont?, color: UIColor?) {
        do {
            self.attributedText = try NSMutableAttributedString(data: text.data(using: .utf8)!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.plain], documentAttributes: nil)
        } catch {
            self.text = text
        }
        self.font = font
        self.textColor = color
    }
}
