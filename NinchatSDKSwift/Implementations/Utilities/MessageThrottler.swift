//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

final class MessageThrottler {
    typealias ThrottlerCompletion = ((InboundMessage) -> Void)
    private let completion: ThrottlerCompletion
    private var messages: [InboundMessage] = []
    private var timer: Timer? = nil
    
    init(with completion: @escaping ThrottlerCompletion) {
        self.completion = completion
        self.messages = []
    }
    
    func add(message: InboundMessage) {
        /// Insert the message into the list of messages by its ID
        self.messages.append(message)
        self.messages.sort(by: { $0.messageID.compare($1.messageID) != .orderedDescending })
        
        DispatchQueue.main.async {
            guard self.timer == nil else { return }
            self.startTimer()
        }
    }
    
    func stop() {
        self.stopTimer()
        self.messages.removeAll()
    }
}

extension MessageThrottler {
    private func startTimer() {
        self.timer = Timer(timeInterval: TimeConstants.kTimerTickInterval.rawValue, repeats: true) { [unowned self] timer in
            var sentMessages: [InboundMessage] = []
            for message in self.messages where (message.created.timeIntervalSinceNow * -1 > TimeConstants.kMessageMaxAge.rawValue) {
                self.completion(message)
                sentMessages.append(message)
            }
            
            self.messages.removeAll(where: { sentMessages.contains($0) })
            if self.messages.isEmpty {
                self.stopTimer()
            }
        }
        RunLoop.main.add(self.timer!, forMode: .default)
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
}