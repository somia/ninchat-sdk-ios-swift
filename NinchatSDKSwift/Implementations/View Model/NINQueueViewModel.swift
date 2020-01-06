//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import NinchatSDK

protocol NINQueueViewModel {
    var onInfoTextUpdate: ((String?) -> Void)? { get set }
    var onQueueJoin: ((Error?) -> Void)? { get set }
    
    init(sessionManager: NINChatSessionManager, queue: NINQueue, delegate: NINChatSessionInternalDelegate?)
    func connect()
}

struct NINQueueViewModelImpl: NINQueueViewModel {
    
    private unowned let sessionManager: NINChatSessionManager
    private unowned let queue: NINQueue
    private weak var delegate: NINChatSessionInternalDelegate?
    
    // MARK: - NINQueueViewModel
    
    var onInfoTextUpdate: ((String?) -> Void)?
    var onQueueJoin: ((Error?) -> Void)?
    
    init(sessionManager: NINChatSessionManager, queue: NINQueue, delegate: NINChatSessionInternalDelegate?) {
        self.sessionManager = sessionManager
        self.queue = queue
        self.delegate = delegate
    }
    
    func connect() {
        do {
            try self.sessionManager.join(queue: queue.queueID, progress: { error, progress in
                if let error = error {
                    self.delegate?.log(format: "Failed to join the queue: %@", error.localizedDescription)
                    self.onQueueJoin?(error)
                }
                self.onInfoTextUpdate?(self.queueTextInfo(progress))
            }, completion: {
                self.onQueueJoin?(nil)
            })
        } catch {
            self.onQueueJoin?(error)
        }
    }
}

// MARK: - Private helpers

extension NINQueueViewModelImpl {
    private func queueTextInfo(_ progress: Int) -> String? {
        switch progress {
        case 1:
            return self.sessionManager.translate(key: Constants.kQueuePositionNext.rawValue,
                                                 formatParams: ["audienceQueue.queue_attrs.name": "\(progress)"])
        default:
            return self.sessionManager.translate(key: Constants.kQueuePositionN.rawValue,
                                                 formatParams: ["audienceQueue.queue_position": "\(progress)"])
        }
    }
}
