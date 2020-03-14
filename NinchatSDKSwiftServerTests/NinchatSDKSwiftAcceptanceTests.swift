//
// Copyright (c) 13.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

/// Acceptance Tests.
/// Tests are run with some configuration to run and open 'dev' environment
class NinchatSDKSwiftAcceptanceTests: XCTestCase {
    private var sessionManager = Session.Manager
    
    func testServer_1_fetchSiteConfigurations() {
        let expect = self.expectation(description: "Expected to fetch site configurations")
        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.audienceQueues)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.audienceRealm)
            XCTAssertTrue(self.sessionManager.siteConfiguration.audienceQueues?.contains(Session.suiteQueue) ?? false)
            expect.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testServer_2_openSession() {
        let expect = self.expectation(description: "Expected to open a session")
        do {
            try self.sessionManager.openSession { error in
                XCTAssertNil(error)
            }
            self.sessionManager.onActionSessionEvent = { event, error in
                XCTAssertNil(error)
                XCTAssertEqual(event, Events.sessionCreated)
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 5.0)
    }

    func testServer_3_listQueues() {
        let expect = self.expectation(description: "Expected to get objects for queue ids")
        do {
            try self.sessionManager.list(queues: self.sessionManager.siteConfiguration.audienceQueues) { error in
                XCTAssertNil(error)
                XCTAssertNotNil(self.sessionManager.queues)
                XCTAssertGreaterThan(self.sessionManager.queues.count, 0)
                XCTAssertEqual(self.sessionManager.queues.map({ $0.queueID }).sorted(), self.sessionManager.siteConfiguration.audienceQueues?.sorted())
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 15.0)
    }

    func testServer_4_joinQueue() {
        let expect_join = self.expectation(description: "Expected to join the queue")
        let expect_progress = self.expectation(description: "Expected to get progress update for the first time")
    
        do {
            /// Join the first time in the queue
            try self.sessionManager.join(queue: Session.suiteQueue, progress: { error, position in
                XCTAssertNil(error)
                XCTAssertNotNil(position)
                XCTAssertEqual(position, 1)
                expect_progress.fulfill()
            }, completion: {
                expect_join.fulfill()
            })
        } catch {
            XCTFail(error.localizedDescription)
        }

        /// The test needs a manual interaction from server to fulfills all expectations
        waitForExpectations(timeout: 150.0)
    }
    
    func testServer_5_startVideoChat() {
        let expect_call = self.expectation(description: "Expected to get a call request")
        let expect_offer = self.expectation(description: "Expected to get a call offer")
        let expect_hangup = self.expectation(description: "Expected to hangup the offer")
    
        try! self.simulateTextMessage("Start a new video chat to run tests")
    
        self.sessionManager.onRTCSignal = { type, user, signal in
            XCTAssertNotNil(signal)
            XCTAssertNotNil(user)
        
            if type == .call {
                XCTAssertNil(signal?.candidate)
                XCTAssertNil(signal?.sdp)
            
                try! self.sessionManager.send(type: .pickup, payload: ["answer": true]) { error in
                    try! self.simulateTextMessage("Now hangup to continue running tests")
                    XCTAssertNil(error)
                }
                expect_call.fulfill()
            }
        
            if type == .offer {
                try! self.sessionManager.beginICE { error, stunServers, turnServers in
                    XCTAssertNil(error)
                    XCTAssertNotNil(stunServers)
                    XCTAssertNotNil(turnServers)
                
                    /// Due to simulator constraints, we cannot test WebRTC by unit tests.
                    /// Unit tests in iOS frameworks work only on simulators (not actual devices)
                    self.sessionManager.onRTCClientSignal = { type, user, signal in
                        XCTAssertNotNil(signal)
                        XCTAssertNotNil(user)
                    }
                }
                expect_offer.fulfill()
            }
        
            if type == .hangup {
                expect_hangup.fulfill()
            }
        }
    
        /// wait until supervisor initiate a call
        waitForExpectations(timeout: 30.0)
    }
    
    func testServer_6_transferQueue() {
        try! self.simulateTextMessage("Now transfer to another queue to continue tests")
        let expect = self.expectation(description: "Expected to get transferred to another queue")
        
        self.sessionManager.bindQueueUpdate(closure: { events, queueID, error in
            XCTAssertNil(error)
            XCTAssertNotNil(events)
            XCTAssertEqual(events, Events.audienceEnqueued)
            XCTAssertNotNil(queueID)
            XCTAssertNotEqual(queueID, Session.suiteQueue)
        }, to: self)
        
        XCTAssertNotNil(self.sessionManager.currentChannelID)
        
        sleep(10)
        do {
            try self.sessionManager.part(channel: self.sessionManager.currentChannelID!) { error in
                XCTAssertNil(error)
                self.sessionManager.unbindQueueUpdateClosure(from: self)
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        /// The test needs a manual interaction from server to fulfills all expectations
        waitForExpectations(timeout: 50.0)
    }
    
    func testServer_7_leaveQueue() {
        let expect = self.expectation(description: "Expected to leave current queue")
        self.sessionManager.leave { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
    
        waitForExpectations(timeout: 5.0)
    }
    
    func testServer_8_deallocate() {
        let expect = self.expectation(description: "Expected to delete user and close the session")
        do {
            try self.sessionManager.deleteCurrentUser { error in
                XCTAssertNil(error)
                self.sessionManager.disconnect()
                sleep(5)
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    
        waitForExpectations(timeout: 5.0)
    }
}

extension NinchatSDKSwiftAcceptanceTests: QueueUpdateCapture {
    internal func simulateTextMessage(_ message: String) throws {
        try self.sessionManager.send(message: message, completion: { _ in })
    }
    
    var desc: String {
        "NinchatSDKSwiftServerInternalTests"
    }
}
