//
// Copyright (c) 22.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

extension UITextView {
    func updateSize(to height: CGFloat) {
        /// Update height constraint value if exists.
        guard let heightConstraint = self.constraints.filter({
            if let item = $0.firstItem as? UITextView {
                return item == self && $0.firstAttribute == .height
            }
            return false
        }).first else {
            fatalError("Height constraint must have been set in IB!")
        }
        heightConstraint.constant = height
        
        self.superview?.setNeedsLayout()
        self.superview?.layoutIfNeeded()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func newSize(maxHeight: CGFloat = 9999) -> CGFloat {
        let newHeight = ceil(self.sizeThatFits(CGSize(width: self.bounds.width, height: 9999)).height)
        return min(newHeight, maxHeight)
    }
    
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let topOffset = (bounds.size.height - sizeThatFits(fittingSize).height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }

    func setPlain(text: String) {
        do {
            self.attributedText = try NSMutableAttributedString(data: text.data(using: .utf8)!, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.plain], documentAttributes: nil)
        } catch {
            self.text = text
        }
    }
}
