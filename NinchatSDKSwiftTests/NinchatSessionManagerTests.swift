//
// Copyright (c) 26.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

class NinchatSessionManagerTests: XCTestCase {
    var sessionSwift: NINChatSessionSwift!
    var sessionManager: NINChatSessionManager!
    
    override func setUp() {
        sessionSwift = NINChatSessionSwift(configKey: "")
        sessionManager = NINChatSessionManagerImpl(session: sessionSwift, serverAddress: "")
    }

    override func tearDown() { }
    
    func testProtocolConformance() {
        XCTAssertNotNil(sessionManager)
        XCTAssertNotNil(sessionManager as NINChatSessionConnectionManager)
        XCTAssertNotNil(sessionManager as NINChatSessionMessanger)
        XCTAssertNotNil(sessionManager as NINChatSessionManagerDelegate)
        XCTAssertNotNil(sessionManager as NINChatSessionManager)
    }
}

class NinchatSessionManagerPrivateTests: XCTestCase {
    var sessionSwift: NINChatSessionSwift!
    var sessionManager: NINChatSessionManagerImpl!
    var param: NINLowLevelClientProps!
    
    override func setUp() {
        sessionSwift = NINChatSessionSwift(configKey: "")
        sessionManager = NINChatSessionManagerImpl(session: sessionSwift, serverAddress: "")
    }

    func testIndexOfItem() {
        let array = ["a", "b", "c", "b"]
        let d = array.filter({ $0 == "d" }).first
        XCTAssertNil(d)
        
        let b = array.filter({ $0 == "b" }).first
        XCTAssertNotNil(b)
        XCTAssertEqual((array as NSArray).index(of: b!), 1)
    }
}

class NinchatSessionManagerClosureHandlersTests: XCTestCase {
    var sessionSwift: NINChatSessionSwift!
    var sessionManager: NINChatSessionManagerImpl!
    
    override func setUp() {
        sessionSwift = NINChatSessionSwift(configKey: "")
        sessionManager = NINChatSessionManagerImpl(session: sessionSwift, serverAddress: "")
    }
    
    func testBindErrorClosures() {
        let expectation1 = self.expectation(description: "The first action is called")
        sessionManager.bind(action: 0) { _ in
            expectation1.fulfill()
        }
        
        let expectation2 = self.expectation(description: "The first action is called")
        sessionManager.bind(action: 1) { error in
            XCTAssertNotNil(error)
            expectation2.fulfill()
        }
        
        sessionManager.onActionID?(0, nil)
        sessionManager.onActionID?(1, NinchatError(code: 0, title: "title"))
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testUnbindErrorClosures() {
        sessionManager.bind(action: 0) { _ in
            XCTFail()
        }
        
        let expectation = self.expectation(description: "The closure should be called")
        sessionManager.bind(action: 1) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        sessionManager.unbind(action: 0)
        sessionManager.onActionID?(0, nil)
        sessionManager.onActionID?(1, NinchatError(code: 0, title: "title"))
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
