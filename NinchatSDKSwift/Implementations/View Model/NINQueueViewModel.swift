//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol NINQueueViewModel {
    var onInfoTextUpdate: ((String?) -> Void)? { get set }
    var onQueueJoin: ((Error?) -> Void)? { get set }

    init(sessionManager: NINChatSessionManager, queue: Queue, delegate: NINChatSessionInternalDelegate?)
    func connect()
}

final class NINQueueViewModelImpl: NINQueueViewModel {
    
    private unowned var sessionManager: NINChatSessionManager!
    private let queue: Queue
    private weak var delegate: NINChatSessionInternalDelegate?
    
    // MARK: - NINQueueViewModel
    
    var onInfoTextUpdate: ((String?) -> Void)?
    var onQueueJoin: ((Error?) -> Void)?
    
    init(sessionManager: NINChatSessionManager, queue: Queue, delegate: NINChatSessionInternalDelegate?) {
        self.sessionManager = sessionManager
        self.delegate = delegate
        self.queue = queue

        self.sessionManager.unbindQueueUpdateClosure(from: self)
    }
    
    func connect() {
        self.connect(queue.queueID)
    }
}

// MARK: - Private helpers

extension NINQueueViewModelImpl {
    private func connect(_ id: String) {
        do {
            try self.sessionManager.join(queue: id, progress: { [unowned self] error, progress in
                if let error = error {
                    self.delegate?.log(format: "Failed to join the queue: %@", error.localizedDescription)
                    self.onQueueJoin?(error)
                }
                self.onInfoTextUpdate?(self.queueTextInfo(progress))
            }, completion: { [unowned self] in
                self.onQueueJoin?(nil)
                self.sessionManager.bindQueueUpdate(closure: { _, queueID, error in
                    guard error == nil else {
                        try? self.sessionManager.closeChat(); return
                    }
                    self.connect(queueID)
                }, to: self)
            })
        } catch {
            self.onQueueJoin?(error)
        }
    }

    private func queueTextInfo(_ progress: Int) -> String? {
        switch progress {
        case 1:
            return self.sessionManager.translate(key: Constants.kQueuePositionNext.rawValue, formatParams: ["audienceQueue.queue_attrs.name": "\(queue.name)"])
        default:
            return self.sessionManager.translate(key: Constants.kQueuePositionN.rawValue, formatParams: ["audienceQueue.queue_attrs.name": "\(queue.name)",
                                                                                                         "audienceQueue.queue_position": "\(progress)"])
        }
    }
}

// MARK: - QueueUpdateCapture

extension NINQueueViewModelImpl: QueueUpdateCapture {
    var desc: String {
        "NINQueueViewModel"
    }
}