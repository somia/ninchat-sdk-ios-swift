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
    private var credentials: NINSessionCredentials! {
        get {
            let dict = UserDefaults.standard.value(forKey: "test_credentials") as! [AnyHashable: Any]
            return try! JSONDecoder().decode(NINSessionCredentials.self, from: dict.toData!)
        }
        set {
            UserDefaults.standard.setValue(newValue.toDictionary, forKey: "test_credentials")
            UserDefaults.standard.synchronize()
        }
    }
    private var onEvent: ((Events?, Error?) -> Void)?

    override func setUp() {
        super.setUp()

        self.sessionManager.delegate = self
    }

    func testServer_00_fetchSiteConfigurations() {
        let expect = self.expectation(description: "Expected to fetch site configurations")
        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.audienceQueues)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.audienceRealm)
            XCTAssertTrue(self.sessionManager.siteConfiguration.audienceQueues?.contains(Session.suiteQueue) ?? false)
            expect.fulfill()
        }

        wait(for: [expect], timeout: 10.0)
    }

    func testServer_01_openSession() {
        let expect = self.expectation(description: "Expected to open a session")
        do {
            try self.sessionManager.openSession { credentials, canResume, error in
                XCTAssertNil(error)
                XCTAssertNotNil(credentials)
                XCTAssertTrue(canResume)
            }
            self.sessionManager.onActionSessionEvent = { credentials, event, error in
                XCTAssertNil(error)
                XCTAssertEqual(event, Events.sessionCreated)

                XCTAssertNotNil(credentials)
                XCTAssertNotNil(credentials?.userID)
                XCTAssertNotEqual(credentials?.userID, "")
                XCTAssertNotNil(credentials?.userAuth)
                XCTAssertNotEqual(credentials?.userAuth, "")
                XCTAssertNotNil(credentials?.sessionID)
                XCTAssertNotEqual(credentials?.sessionID, "")

                self.credentials = credentials!
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        wait(for: [expect], timeout: 10.0)
    }

    func testServer_02_listQueues() {
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

        wait(for: [expect], timeout: 15.0)
    }

    func testServer_03_joinQueue() {
        let expect_join = self.expectation(description: "Expected to join the queue")
        let expect_progress = self.expectation(description: "Expected to get progress update for the first time")
        expect_progress.assertForOverFulfill = false
    
        do {
            /// Join the first time in the queue
            try self.sessionManager.join(queue: Session.suiteQueue, progress: { queue, error, position in
                XCTAssertNil(error)
                XCTAssertNotNil(queue)
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
        wait(for: [expect_join, expect_progress], timeout: 150.0)
    }
    
    func testServer_04_startVideoChat() {
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

    func testServer_05_leaveQueue() {
        let expect = self.expectation(description: "Expected to leave current queue")
        self.sessionManager.leave { error in
            XCTAssertNil(error)
            expect.fulfill()
        }

        wait(for: [expect], timeout: 10.0)
    }

    func testServer_06_resumeSession() {
        let expect = self.expectation(description: "Expected to continue a session using credentials")
        expect.assertForOverFulfill = false

        do {
            self.sessionManager.onMessageAdded = { _ in
                expect.fulfill()
            }

            try self.sessionManager.continueSession(credentials: self.credentials) { newCredentials, canResume, error in
                XCTAssertNil(error)
                XCTAssertNotNil(newCredentials)
                /// The new credentials contains only the new session ID
                XCTAssertEqual(newCredentials?.userID, self.credentials.userID, "The new credentials should come with the same user id")
                XCTAssertEqual(newCredentials?.userAuth, "", "The new credentials should come with an empty user auth")
                XCTAssertNotEqual(newCredentials?.sessionID, self.credentials.sessionID, "The new credentials should come with the new session id")

                XCTAssertTrue(canResume)
            }

            try self.sessionManager.loadHistory { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        wait(for: [expect], timeout: 10.0)
    }

    func testServer_07_transferQueue() {
        try! self.simulateTextMessage("Now transfer to another queue to continue tests")
        let expect_part = self.expectation(description: "Expected to get transferred to another channel")
        expect_part.assertForOverFulfill = false
        let expect_join = self.expectation(description: "Expected to joint the new channel")
        expect_join.assertForOverFulfill = false

        self.sessionManager.onMessageAdded = nil
        self.sessionManager.bindQueueUpdate(closure: { event, queue, error in
            XCTAssertNil(error)
            XCTAssertNotNil(event)
            XCTAssertEqual(event, Events.audienceEnqueued)
            XCTAssertNotNil(queue)
            XCTAssertNotEqual(queue.queueID, Session.suiteQueue)

            /// Once the user is enqueued, we have to part the current channel
            try! self.sessionManager.part(channel: self.sessionManager.currentChannelID!) { error in
                self.sessionManager.unbindQueueUpdateClosure(from: self)
                XCTAssertNil(error)
            }
        }, to: self)
        XCTAssertNotNil(self.sessionManager.currentChannelID)

        self.onEvent = { event, error in
            XCTAssertNil(error)
            XCTAssertNotNil(event)

            /// Fulfill expectation if the user has successfully transferred to a new channel
            if event == .channelParted {
                expect_part.fulfill()
            } else if event == .channelJoined {
                expect_join.fulfill()
            }
        }
        
        /// The test needs a manual interaction from server to fulfills all expectations
        wait(for: [expect_part, expect_join], timeout: 30.0)
    }

    func testServer_08_loadHistory() {
        let expect = self.expectation(description: "Expected to fetch all messages after the transfer")
        expect.expectedFulfillmentCount = 3

        do {
            self.sessionManager.chatMessages.removeAll()
            self.sessionManager.onMessageAdded = { _ in
                expect.fulfill()
            }
            try self.sessionManager.loadHistory { error in
                XCTAssertNil(error)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 20.0)
    }
    
    func testServer_09_leaveQueue() {
        let expect = self.expectation(description: "Expected to leave current queue")
        self.sessionManager.leave { error in
            XCTAssertNil(error)
            expect.fulfill()
        }

        wait(for: [expect], timeout: 10.0)
    }
    
    func testServer_10_deallocate() {
        let expect = self.expectation(description: "Expected to delete user and close the session")
        do {
            sleep(10)
            try self.sessionManager.deleteCurrentUser { error in
                self.sessionManager.disconnect()

                XCTAssertNil(error)
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        wait(for: [expect], timeout: 10.0)
    }
    
}

extension NinchatSDKSwiftAcceptanceTests: NINChatSessionInternalDelegate {
    func log(value: String) {}

    func log(format: String, _ args: CVarArg...) {}

    func onDidEnd() {}

    func onResumeFailed() -> Bool { true }

    func override(imageAsset key: AssetConstants) -> UIImage? { nil }

    func override(colorAsset key: ColorConstants) -> UIColor? { nil }

    func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
        if case let .failure(error) = event.event { self.onEvent?(nil, error); return }
        self.onEvent?(Events(rawValue: event.event.value), nil)
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
