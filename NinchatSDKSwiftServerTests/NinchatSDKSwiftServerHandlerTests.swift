//
// Copyright (c) 16.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

final class NinchatSDKSwiftServerHandlerTests: XCTestCase {
    private var sessionManager = Session.Manager
    private var expect_session_event: XCTestExpectation!
    private var expect_event: XCTestExpectation!
    
    func testServer_0_sessionEvents() {
        self.expect_session_event = self.expectation(description: "Expected to get session events")
        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { _ in
            try? self.sessionManager.openSession { _,_,_ in }
            self.sessionManager.session?.setOnSessionEvent(self)
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testServer_1_clientEvents() {
        self.expect_event = self.expectation(description: "Expected to get general events")
        try! self.sessionManager.list(queues: self.sessionManager.siteConfiguration.audienceQueues) { error in }
        self.sessionManager.session?.setOnEvent(self)
        
        waitForExpectations(timeout: 5.0)
    }
}


extension NinchatSDKSwiftServerHandlerTests: NINLowLevelClientSessionEventHandlerProtocol {
    func onSessionEvent(_ params: NINLowLevelClientProps?) {
        let event = params?.event.value
        XCTAssertNotNil(event)
    
        let eventType = Events(rawValue: event!)
        XCTAssertNotNil(eventType)
        
        self.expect_session_event.fulfill()
    }
}

extension NinchatSDKSwiftServerHandlerTests: NINLowLevelClientEventHandlerProtocol {
    func onEvent(_ params: NINLowLevelClientProps?, payload: NINLowLevelClientPayload?, lastReply: Bool) {
        XCTAssertNotNil(params)
        XCTAssertNotNil(payload)
    
        let event = params?.event.value
        XCTAssertNotNil(event)
    
        let eventType = Events(rawValue: event!)
        XCTAssertNotNil(eventType)
    
        self.expect_event.fulfill()
    }
}
