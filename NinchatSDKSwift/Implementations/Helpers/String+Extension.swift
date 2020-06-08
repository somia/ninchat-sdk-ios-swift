//
// Copyright (c) 13.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import UIKit

extension String {
    func htmlAttributedString(withFont font: UIFont?, alignment: NSTextAlignment, color: UIColor?) -> NSAttributedString? {
        applyStyle(attrString: attributedString(font, document: .html), alignment, color)
    }
    
    func plainString(withFont font: UIFont?, alignment: NSTextAlignment, color: UIColor?) -> NSAttributedString? {
        applyStyle(attrString: attributedString(font, document: .plain), alignment, color)
    }
    
    private func attributedString(_ font: UIFont?, document: NSAttributedString.DocumentType) -> NSMutableAttributedString? {
        guard let data = self.data(using: .utf16, allowLossyConversion: false), let font = font else { return nil }
        do {
            return try NSMutableAttributedString(data: data, options: [.documentType: document], documentAttributes: nil).override(font: font)
        } catch {
            debugger("error in string conversion. \(error.localizedDescription)")
            return nil
        }
    }
    
    private func applyStyle(attrString: NSAttributedString?, _ alignment: NSTextAlignment, _ color: UIColor?) -> NSAttributedString? {
        guard let attrString = attrString as? NSMutableAttributedString else { return nil }
        
        /// Text alignment
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: attrString.length))
    
        /// Text color
        if let color = color {
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: attrString.length))
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

    var localized: String {
        guard let bundle = Bundle.SDKBundle else { return self }
        return NSLocalizedString(self, tableName: "Localizable", bundle: bundle, value: "", comment: "")
    }
}

extension String {
    func extractRegex(withPattern pattern: String) -> [String]? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            debugger("Error in extracting regex with pattern: \(pattern): \(error)"); return nil
        }
    }
}
