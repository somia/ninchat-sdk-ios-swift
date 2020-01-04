//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import NinchatSDK

protocol NINQueueViewModel {
    var onInfoTextUpdate: ((String?) -> Void)? { get set }
    var onJoinSuccess: (() -> Void)? { get set }
    
    init(session: NINChatSessionSwift, queue: NINQueue)
    func connect()
}

struct NINQueueViewModelImpl: NINQueueViewModel {
    
    private unowned let session: NINChatSessionSwift
    private unowned let queue: NINQueue
    
    // MARK: - NINQueueViewModel
    
    var onInfoTextUpdate: ((String?) -> Void)?
    var onJoinSuccess: (() -> Void)?
    
    init(session: NINChatSessionSwift, queue: NINQueue) {
        self.session = session
        self.queue = queue
    }
    
    func connect() {
        self.session.sessionManager.joinQueue(withId: queue.queueID, progress: { error, progress in
            if let error = error {
                self.session.log(format: "Failed to join the queue: %@", error.localizedDescription)
            }
            self.onInfoTextUpdate?(self.queueTextInfo(progress))
        }, channelJoined: {
            self.onJoinSuccess?()
        })
    }
}

// MARK: - Private helpers

extension NINQueueViewModelImpl {
    private func queueTextInfo(_ progress: Int) -> String? {
        switch progress {
        case 1:
            return session.sessionManager.translation(Constants.kQueuePositionNext.rawValue, formatParams: ["audienceQueue.queue_attrs.name": "\(progress)"])
        default:
            return session.sessionManager.translation(Constants.kQueuePositionN.rawValue, formatParams: ["audienceQueue.queue_position": "\(progress)"])
        }
    }
}
