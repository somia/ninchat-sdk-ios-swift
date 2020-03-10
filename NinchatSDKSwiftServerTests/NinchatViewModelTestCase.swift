//
// Copyright (c) 21.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

class NinchatViewModelTestCase: XCTestCase {
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
    
    func testServerIntegrationTests() {
        XCTAssertTrue(true)
    }
}

extension NinchatViewModelTestCase {
    class func wait(for closure: @escaping (() -> Void)) {
        guard self.lock else { fatalError("Can't wait without the locker being set") }
        closure()
        
        while self.lock {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
    }
}

extension NinchatViewModelTestCase {
    /// open session and join the queue
    private class func initiateSession(_ sessionManager: NINChatSessionManagerImpl, completion: @escaping (() -> Void)) {
        if let _ = sessionManager.siteConfiguration?.audienceQueues {
            completion(); return
        }
        
        sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: nil) { error in
            try! sessionManager.openSession { error in
                completion()
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