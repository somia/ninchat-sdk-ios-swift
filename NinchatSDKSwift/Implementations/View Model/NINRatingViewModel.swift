//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol NINRatingViewModel {
    init(session: NINChatSessionSwift)
    
    func rateChat(with status: ChatStatus)
    func skipRating()
}

struct NINRatingViewModelImpl: NINRatingViewModel {
    
    private unowned let session: NINChatSessionSwift
    
    // MARK: - NINRatingViewModel
    
    init(session: NINChatSessionSwift) {
        self.session = session
    }
    
    func rateChat(with status: ChatStatus) {
        session.sessionManager.finishChat(NSNumber(value: status.rawValue))
    }
    
    func skipRating() {
        session.sessionManager.finishChat(nil)
    }
}
