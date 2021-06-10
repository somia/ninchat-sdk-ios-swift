//
// Copyright (c) 3.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI
import Combine

final class ImageRemoteLoader: ObservableObject {
    enum LoadingState {
        case initial
        case inProgress
        case success(_ image: Image)
        case failure
    }
    
    @Published var loadingState: LoadingState = .initial
    @Published var image: UIImage!
    private var cancellable: AnyCancellable?
    private let url: String
    
    init(_ url: String) {
        self.url = url
    }
    
    func fetch() {
        guard let imgURL = URL(string: self.url) else {
            self.loadingState = .failure; return
        }
        
        self.loadingState = .inProgress
        self.cancellable = URLSession(configuration: .default)
            .dataTaskPublisher(for: imgURL)
            .map {
                guard let img = UIImage(data: $0.data) else {
                    return .failure
                }
                return .success(Image(uiImage: img).resizable())
            }
            .catch { _ in
                Just(.failure)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.loadingState, on: self)
    }
}
