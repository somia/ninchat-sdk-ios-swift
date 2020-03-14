//
// Copyright (c) 13.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension String {
    func htmlAttributedString(withFont font: UIFont?, alignment: NSTextAlignment, color: UIColor?) -> NSAttributedString? {
        attributedString(font, document: .html)
    }
    
    func plainString(withFont font: UIFont?, alignment: NSTextAlignment, color: UIColor?) -> NSAttributedString? {
        applyStyle(attrString: attributedString(font, document: .plain), alignment, color)
    }
    
    private func attributedString(_ font: UIFont?, document: NSAttributedString.DocumentType) -> NSAttributedString? {
        guard let data = self.data(using: .utf8), let font = font else { return nil }
        do {
            let attrString = try NSMutableAttributedString(data: data, options: [.documentType: document], documentAttributes: nil)
            attrString.override(font: font)
        
            return attrString
        } catch {
            debugger("error in string conversion. \(error.localizedDescription)")
            return nil
        }
    }
    
    private func applyStyle(attrString: NSAttributedString?, _ alignment: NSTextAlignment, _ color: UIColor?) -> NSAttributedString? {
        guard var attrString = attrString as? NSMutableAttributedString else { return nil }
        
        /// Text alignment
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: self.count))
    
        /// Text color
        if let color = color {
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: self.count))
        }
        
        return attrString
    }
    
    var containsTags: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "(<\\w+>|<\\w+/>|</\\w+>)", options: .caseInsensitive)
            return regex.matches(in: self, range: NSRange(location: 0, length: self.count)).count > 0
        } catch {
            return false
        }
    }
}