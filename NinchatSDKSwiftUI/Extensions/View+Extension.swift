//
// Copyright (c) 3.5.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

extension View {
    @ViewBuilder
    func round(radius: CGFloat, borderWidth: CGFloat = 0.0, borderColor: Color = .clear) -> some View {
        self
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius).stroke(borderColor, lineWidth: borderWidth)
            )
    }
}

