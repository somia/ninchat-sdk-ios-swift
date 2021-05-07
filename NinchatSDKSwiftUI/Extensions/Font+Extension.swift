//
// Copyright (c) 27.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

extension Font {
    private static var fontName: String {
        "SourceSansPro-\(FontWeight.regular.rawValue)"
    }

    static var ninchat: Font {
        FontWeight.allCases.forEach({ UIFont.register(font: "SourceSansPro-\($0.rawValue)") })
        return Font.custom(fontName, size: 16.0)
    }
}
