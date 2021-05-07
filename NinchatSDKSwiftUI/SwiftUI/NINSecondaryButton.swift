//
// Copyright (c) 6.5.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

struct NINSecondaryButtonView: View {
    private let title: String
    private let size: CGSize
    private let override: ButtonOverride
    private let action: (() -> Void)
    
    // MARK: - Default Styles
    private struct DefaultStyle: ButtonOverride {
        var foregroundColor: (Color?, UIColor?)? = (Color(UIColor.defaultBackgroundButton), .defaultBackgroundButton)
        var backgroundColor: (Color?, UIColor?)? = (.clear, .clear)
        var cornerRadius: CornerRadius? = .rounded
        var borderColor: (Color?, UIColor?)? = (Color(UIColor.defaultBackgroundButton), .defaultBackgroundButton)
        var borderWidth: CGFloat? = nil
        var font: (Font?, UIFont?)? = (.ninchat, .ninchat)
    }
    
    init(_ title: String, size: CGSize?, override: Override?, action: @escaping (() -> Void)) {
        self.title = title
        self.action = action
        self.size = size ?? .zero
        self.override = ButtonOverrideStyle(override, defaultStyle: DefaultStyle())
    }
    
    var body: some View {
        let button = Button(action: { self.action() }) {
            Text(title)
                .frame(width: size.width, height: size.height)
                .foregroundColor(override.foregroundColor!.0)
                .background(override.backgroundColor!.0)
                .font(override.font!.0)
        }
        
        switch override.cornerRadius {
        case .noRadius:
            return button.round(radius: 0.0)
        case .curved(let rad):
            return button.round(radius: rad, borderWidth: override.borderWidth ?? 1.0, borderColor: override.borderColor?.0 ?? .clear)
        case .rounded:
            return button.round(radius: size.height/2, borderWidth: override.borderWidth ?? 1.0, borderColor: override.borderColor?.0 ?? .clear)
        default:
            fatalError("the case is not handled")
        }
    }
}
