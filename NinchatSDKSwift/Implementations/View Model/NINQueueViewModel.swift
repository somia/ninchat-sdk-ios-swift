//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol NINQueueViewModel {
    var resumeMode: Bool! { get set }
    var onInfoTextUpdate: ((String?) -> Void)? { get set }
    var onQueueJoin: ((Error?) -> Void)? { get set }

    init(sessionManager: NINChatSessionManager, delegate: NINChatSessionInternalDelegate?)
    func connect(queue: Queue)
    func registerAudience(queue: Queue)
    func queueTextInfo(queue: Queue?, _ progress: Int) -> String?
}

final class NINQueueViewModelImpl: NINQueueViewModel {
    
    private unowned var sessionManager: NINChatSessionManager!
    private weak var delegate: NINChatSessionInternalDelegate?
    private var readyToJoin: Bool = false

    // MARK: - NINQueueViewModel
    
    var onInfoTextUpdate: ((String?) -> Void)?
    var onQueueJoin: ((Error?) -> Void)?
    var resumeMode: Bool!

    init(sessionManager: NINChatSessionManager, delegate: NINChatSessionInternalDelegate?) {
        self.sessionManager = sessionManager
        self.delegate = delegate

        self.sessionManager.unbindQueueUpdateClosure(from: self)
        self.sessionManager.bindQueueUpdate(closure: { [weak self] event, queue, error in
            if let _ = error { try? self?.sessionManager.closeChat(); return }
            guard (self?.resumeMode ?? false) || (self?.readyToJoin ?? false) else { return }

            self?.connect(queue: queue)
        }, to: self)
    }
    
    func connect(queue: Queue) {
        do {
            try self.sessionManager.join(queue: queue.queueID, progress: { [weak self] queue, error, progress in
                if let error = error {
                    self?.delegate?.log(format: "Failed to join the queue: %@", error.localizedDescription)
                    self?.onQueueJoin?(error)
                }
                self?.onInfoTextUpdate?(self?.queueTextInfo(queue: queue, progress))
            }, completion: { [weak self] in
                self?.onQueueJoin?(nil)
                self?.readyToJoin = true
            })
        } catch {
            self.onQueueJoin?(error)
        }
    }

    func registerAudience(queue: Queue) {
        guard let metadata = self.sessionManager.audienceMetadata else { return }

        do {
            try self.sessionManager?.registerAudience(queue: queue.queueID, answers: metadata) { [weak self] error in
                if let error = error {
                    self?.onInfoTextUpdate?(error.localizedDescription); return
                }

                self?.onInfoTextUpdate?(self?.sessionManager.siteConfiguration.audienceRegisteredClosedText)
            }
        } catch {
            self.onInfoTextUpdate?(error.localizedDescription)
        }
    }

    deinit {
        self.onInfoTextUpdate = nil
        self.onQueueJoin = nil
    }

    func queueTextInfo(queue: Queue?, _ progress: Int) -> String? {
        guard let queue = queue else { return "" }

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
