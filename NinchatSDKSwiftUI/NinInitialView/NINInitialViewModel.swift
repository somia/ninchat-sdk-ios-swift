//
// Copyright (c) 28.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Combine

final class NINInitialViewModel: ObservableObject {
    
    private(set) var title: String = ""
    private(set) var queuesTitles: [String] = []
    private(set) var cancel: String = ""
    private(set) var motd: String = ""
    private(set) var noQueueText: String = ""
    private(set) var queues: [Queue] = []
    
    var onQueueTapped: ((Queue) -> Void)?
    var onCancelTapped: (() -> Void)?
    
    init(session: NINChatSessionManager) {
        title = session.siteConfiguration.welcome ?? ""
        queues = session.audienceQueues.filter({ !$0.isClosed })
        queuesTitles = queues.compactMap({
            session.translate(key: Constants.kJoinQueueText.rawValue, formatParams: ["audienceQueue.queue_attrs.name": $0.name])
        })
        cancel = session.translate(key: Constants.kCloseWindowText.rawValue, formatParams: [:]) ?? ""
        motd = session.siteConfiguration.motd ?? ""
        noQueueText = session.siteConfiguration.noQueueText ?? "NoQueueText".localized
    }
}

// MARK: - User Actions

extension NINInitialViewModel {
    func onQueueTapped(_ title: String) {
        guard let queueIndex = queuesTitles.index(of: title) else { return }
        onQueueTapped?(queues[queueIndex])
    }
}
