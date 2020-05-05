//
// Copyright (c) 14.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

class NinchatXCTestCase: XCTestCase {
    internal var sessionManager = Session.Manager
    internal static var lock: Bool = false
    
    override class func setUp() {
        super.setUp()
        
        self.lock = true
        self.wait {
            self.initiateSession(Session.Manager) {
                self.lock = false
            }
        }
    }
    
    override class func tearDown() {
        super.tearDown()
    
        self.lock = true
        self.wait {
            self.deallocateSession(Session.Manager) {
                self.lock = false
            }
        }
    }
}

extension NinchatXCTestCase {
    class func wait(for closure: @escaping (() -> Void)) {
        guard self.lock else { fatalError("Can't wait without the locker being set") }
        closure()
        
        while self.lock {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
    }
}

extension NinchatXCTestCase {
    /// open session and join the queue
    private class func initiateSession(_ sessionManager: NINChatSessionManagerImpl, completion: @escaping (() -> Void)) {
        if let _ = sessionManager.siteConfiguration?.audienceQueues {
            completion(); return
        }
    
        sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: nil) { error in
            try! sessionManager.openSession { credentials, canResume, error in
                debugger("** ** UnitTest: credentials: \(credentials!)")
                try! sessionManager.list(queues: sessionManager.siteConfiguration.audienceQueues) { error in
                    try! sessionManager.join(queue: Session.suiteQueue, progress: { queue, error, position in }, completion: {
                        completion()
                    })
                }
            }
        }
    }
    
    /// leave the queue and disconnect
    private class func deallocateSession(_ sessionManager: NINChatSessionManagerImpl, completion: @escaping (() -> Void)) {
        sessionManager.didEndSession = {
            completion()
        }
        sessionManager.leave { error in
            try! sessionManager.closeChat()
        }
    }
}

extension NinchatXCTestCase {
    internal func simulateTextMessage(_ message: String) {
        try! self.sessionManager.send(message: message, completion: { _ in })
    }
    
    internal func simulateSendAttachment() {
        let image = UIImage(named: "icon_face_happy", in: Bundle.SDKBundle, compatibleWith: nil)?.pngData()
        try! self.sessionManager.send(attachment: "attachment", data: image!) { _ in }
    }
}
