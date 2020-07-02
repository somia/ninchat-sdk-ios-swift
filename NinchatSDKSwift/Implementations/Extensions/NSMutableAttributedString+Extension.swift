//
// Copyright (c) 13.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import CoreText

extension NSMutableAttributedString {
    func override(font: UIFont) -> Self {
        self.beginEditing()
        self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { (value, range, stop) in
            if let stringFont = value as? UIFont, let fontDescriptor = stringFont.fontDescriptor.withFamily(font.familyName).withSymbolicTraits(stringFont.fontDescriptor.symbolicTraits) {
                let newFont = UIFont(descriptor: fontDescriptor, size: font.pointSize)

                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
            }
        }
        self.endEditing()

        return self
    }

    @discardableResult
    func setColor(to text: String, color: UIColor) -> Self {
        let range = self.mutableString.range(of: text, options: .caseInsensitive)
        if range.location != NSNotFound {
            self.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        }
        return self
    }
}
