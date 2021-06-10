//
// Copyright (c) 3.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

struct RemoteImage: View {
    private let delegate: NINChatSessionInternalDelegate?
    @ObservedObject private var loader: ImageRemoteLoader
    
    init(from url: String, delegate: NINChatSessionInternalDelegate?) {
        self.delegate = delegate
        self.loader = ImageRemoteLoader(url)
        self.loader.fetch()
    }

    var body: some View {
        Group {
            switch loader.loadingState {
            case .initial, .failure:
                Rectangle()
                    .fill(Color(/*self.delegate?.override(colorAsset: .ninchatColorButtonCloseChatText) ?? */.tPlaceholderGray))
                    .cornerRadius(20.0)
            case .inProgress:
                ActivityIndicator(isAnimating: false)
            case .success(let image):
                image
            }
        }
    }
}
