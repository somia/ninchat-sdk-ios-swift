//
// Copyright (c) 13.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import UIKit

extension String {

    func htmlAttributedString(withFont font: UIFont?, alignment: NSTextAlignment, color: UIColor?, width: CGFloat?) -> NSAttributedString? {
        /// To limit embedded images to the given width
        let widthStyle = (width != nil) ? "img{ max-height: 100%; max-width: \(width!) !important; width: auto; height: auto;}" : ""
        /// Setting font for HTML texts with the same approach with plain strings does not work properly,
        /// and it causes issues in rendering complex ones
        let fontStyle = (font != nil) ? "p { font-family: \(font!.familyName); font-size: \(font!.pointSize)px; }" : ""
        let input = String(format: """
                                   <head>
                                        <style>
                                             %@
                                             %@
                                        </style>
                                   </head>
                                   <body>
                                        <p>\(self)</p>
                                   </body>
                                   """, arguments: [widthStyle, fontStyle])
        return applyStyle(attrString: attributedString(input, document: .html, width: width), font, alignment, color)
    }
    
    func plainString(withFont font: UIFont?, alignment: NSTextAlignment, color: UIColor?) -> NSAttributedString? {
        applyStyle(attrString: attributedString(self, document: .plain, width: nil), font, alignment, color)
    }
    
    private func attributedString(_ input: String, document: NSAttributedString.DocumentType, width: CGFloat?) -> NSMutableAttributedString? {
        guard let data = input.data(using: .utf16, allowLossyConversion: true) else { return nil }
        do {
            return try NSMutableAttributedString(data: data, options: [.documentType: document], documentAttributes: nil)
        } catch {
            debugger("error in string conversion. \(error.localizedDescription)")
            return nil
        }
    }
    
    private func applyStyle(attrString: NSAttributedString?, _ font: UIFont?, _ alignment: NSTextAlignment, _ color: UIColor?) -> NSMutableAttributedString? {
        guard let attrString = attrString as? NSMutableAttributedString else { return nil }
        
        /// Text alignment
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: attrString.length))

        /// Text color
        if let color = color {
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: attrString.length))
        }

        /// Text Font
        if let font = font {
            _ = attrString.override(font: font)
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
    @discardableResult
    func setColor(to text: String, color: UIColor) -> NSMutableAttributedString {
        NSMutableAttributedString(string: self).applyUpdates(to: text, color: color)
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
