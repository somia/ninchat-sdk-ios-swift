//
// Copyright (c) 6.5.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

typealias Override = NinchatSwiftUIOverrideOptions
typealias ButtonOverride = NinchatSwiftUIButtonOverrideOptions
typealias TextOverride = NinchatSwiftUITextOverrideOptions
typealias ViewOverride = NinchatSwiftUIViewOverridingOptions

struct ButtonOverrideStyle: ButtonOverride {
    var foregroundColor: (Color?, UIColor?)?
    var backgroundColor: (Color?, UIColor?)?
    var cornerRadius: CornerRadius?
    var borderColor: (Color?, UIColor?)?
    var borderWidth: CGFloat?
    var font: (Font?, UIFont?)?
    
    init(_ style: Override?, defaultStyle: ButtonOverride) {
        guard let buttonStyle = style as? ButtonOverride else {
            foregroundColor = defaultStyle.foregroundColor
            backgroundColor = defaultStyle.backgroundColor
            cornerRadius = defaultStyle.cornerRadius
            borderColor = defaultStyle.borderColor
            borderWidth = defaultStyle.borderWidth
            font = defaultStyle.font
            return
        }
        
        foregroundColor = buttonStyle.foregroundColor ?? defaultStyle.foregroundColor
        backgroundColor = buttonStyle.backgroundColor ?? defaultStyle.backgroundColor
        cornerRadius = buttonStyle.cornerRadius ?? defaultStyle.cornerRadius
        borderColor = buttonStyle.borderColor ?? defaultStyle.borderColor
        borderWidth = buttonStyle.borderWidth ?? defaultStyle.borderWidth
        font = buttonStyle.font ?? defaultStyle.font
    }
}

struct TextOverrideStyle: TextOverride {
    var textColor: (Color?, UIColor?)?
    var linkColor: (Color?, UIColor?)?
    var font: (Font?, UIFont?)?
    
    init(_ style: Override?, defaultStyle: TextOverride) {
        guard let buttonStyle = style as? TextOverride else {
            textColor = defaultStyle.textColor
            linkColor = defaultStyle.linkColor
            font = defaultStyle.font
            return
        }
        
        textColor = buttonStyle.textColor ?? defaultStyle.textColor
        linkColor = buttonStyle.linkColor ?? defaultStyle.linkColor
        font = buttonStyle.font ?? defaultStyle.font
    }
}

struct ViewOverrideStyle: ViewOverride {
    var backgroundColor: (Color?, UIColor?)?
    
    init(_ style: Override?, defaultStyle: ViewOverride) {
        guard let buttonStyle = style as? ViewOverride else {
            backgroundColor = defaultStyle.backgroundColor
            return
        }
        
        backgroundColor = buttonStyle.backgroundColor ?? defaultStyle.backgroundColor
    }
}
