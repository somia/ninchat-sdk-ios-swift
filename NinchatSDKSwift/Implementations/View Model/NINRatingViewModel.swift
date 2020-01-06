//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol NINRatingViewModel {
    init(sessionManager: NINChatSessionManager)
    
    func rateChat(with status: ChatStatus)
    func skipRating()
}

struct NINRatingViewModelImpl: NINRatingViewModel {
    
    private unowned let sessionManager: NINChatSessionManager
    
    // MARK: - NINRatingViewModel
    
    init(sessionManager: NINChatSessionManager) {
        self.sessionManager = sessionManager
    }
    
    func rateChat(with status: ChatStatus) {
        try? self.sessionManager.finishChat(rating: status)
    }
    
    func skipRating() {
        try? self.sessionManager.finishChat(rating: nil)
    }
}
