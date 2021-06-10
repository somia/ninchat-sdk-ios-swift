//
// Copyright (c) 3.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView {
        let view = UIView()
        view.style = .large
        view.hidesWhenStopped = true
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
