//
//  NINRatingViewModel.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 24.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import Foundation

enum ChatStatus: Int {
    case happy = 1
    case neutral = 0
    case sad = -1
}

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
