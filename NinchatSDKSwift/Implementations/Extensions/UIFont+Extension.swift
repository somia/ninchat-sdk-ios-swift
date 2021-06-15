//
// Copyright (c) 28.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

enum FontWeight: String, CaseIterable {
    case light      = "Light"
    case regular    = "Regular"
    case semiBold   = "SemiBold"
    case bold       = "Bold"
}

extension UIFont {
    private static var fontName: String {
        "SourceSansPro-\(FontWeight.regular.rawValue)"
    }
    
    static var ninchat: UIFont? {
        FontWeight.allCases.forEach({ register(font: "SourceSansPro-\($0.rawValue)") })
        return UIFont(name: fontName, size: 16.0)
    }
    
    static var ninchatSemiBold: UIFont? {
        FontWeight.allCases.forEach({ register(font: "SourceSansPro-\($0.rawValue)") })
        return UIFont(name: "SourceSansPro-\(FontWeight.semiBold.rawValue)", size: 16.0)
    }
    
    static var ninchatLight: UIFont? {
        FontWeight.allCases.forEach({ register(font: "SourceSansPro-\($0.rawValue)") })
        return UIFont(name: "SourceSansPro-\(FontWeight.light.rawValue)", size: 16.0)
    }

    static var subtitleNinchat: UIFont? {
        FontWeight.allCases.forEach({ register(font: "SourceSansPro-\($0.rawValue)") })
        return UIFont(name: fontName, size: 12.0)
    }

    @discardableResult
    static func register(font: String) -> Bool {
        guard let pathForResourceString = Bundle.SDKBundle?.path(forResource: font, ofType: "ttf"),
              let fontData = NSData(contentsOfFile: pathForResourceString),
              let dataProvider = CGDataProvider(data: fontData),
              let fontRef = CGFont(dataProvider)
            else { return false }
        
        var errorRef: Unmanaged<CFError>? = nil
        defer { _ = errorRef?.autorelease() }
        return CTFontManagerRegisterGraphicsFont(fontRef, &errorRef)
    }
}
