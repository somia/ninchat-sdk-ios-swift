//
// Copyright (c) 27.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI
import WebKit

struct NINAttributedText: UIViewRepresentable {
    private let text: String
    private let alignment: NSTextAlignment
    private let override: TextOverride

    // MARK: - Default Styles
    private struct DefaultStyle: TextOverride {
        var textColor: (Color?, UIColor?)? = (.black, .black)
        var linkColor: (Color?, UIColor?)? = (.blue, .blue)
        var font: (Font?, UIFont?)? = (.ninchat, .ninchat)
    }
    
    init(_ text: String, alignment: NSTextAlignment = .left, override: Override?) {
        self.text = text
        self.alignment = alignment
        self.override = TextOverrideStyle(override, defaultStyle: DefaultStyle())
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textAlignment = alignment
        textView.textColor = override.textColor!.1
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: override.linkColor!.1]
        
        DispatchQueue.main.async {
            textView.setAttributed(text: text, font: override.font!.1)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {}
}
