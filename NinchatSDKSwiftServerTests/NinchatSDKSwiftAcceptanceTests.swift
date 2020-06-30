//
// Copyright (c) 13.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import WebRTC
import NinchatLowLevelClient
@testable import NinchatSDKSwift

/// Acceptance Tests.
/// Tests are run with some configuration to run and open 'dev' environment
class NinchatSDKSwiftAcceptanceTests: XCTestCase, NINChatWebRTCClientDelegate {
    private var sessionManager = Session.Manager
    private var rtcClient: NINChatWebRTCClient?
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

    // MARK: - NINChatWebRTCClientDelegate
    var onConnectionStateChange: ((NINChatWebRTCClient, ConnectionState) -> Void)?
    var onLocalCaptureCreate: ((NINChatWebRTCClient, RTCCameraVideoCapturer) -> Void)?
    var onRemoteVideoTrackReceive: ((NINChatWebRTCClient, RTCVideoTrack) -> Void)?
    var onError: ((NINChatWebRTCClient, Error) -> Void)?

    override func setUp() {
        super.setUp()

        self.sessionManager.delegate = self
    }

    // MARK: - start

    func testServer_01_fetchSiteConfigurations() {
        let expect = self.expectation(description: "Expected to fetch site configurations")
        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.audienceQueues)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.audienceRealm)
            XCTAssertTrue(self.sessionManager.siteConfiguration.audienceQueues?.contains(Session.suiteQueue) ?? false)

            XCTAssertNotNil(self.sessionManager.siteConfiguration.preAudienceQuestionnaire)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.postAudienceQuestionnaire)
            expect.fulfill()
        }

        wait(for: [expect], timeout: 10.0)
    }

    func testServer_02_openSession() {
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

    func testServer_03_listQueues() {
        let expect = self.expectation(description: "Expected to get objects for queue ids")
        expect.assertForOverFulfill = false

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

    func testServer_04_setPreAudienceQuestionnaire() {
        let pre_answers: [String:AnyHashable] = ["Questionnaire_pre_1": "Answer_pre_1", "Questionnaire_pre_2": "Answer_pre_2"]
        self.sessionManager.preAudienceQuestionnaireMetadata = NINLowLevelClientProps.initiate(metadata: pre_answers)

        XCTAssertTrue(true)
    }

    func testServer_05_joinQueue() {
        let expect_join = self.expectation(description: "Expected to join the queue")
        let expect_progress = self.expectation(description: "Expected to get progress update for the first time")
        expect_progress.assertForOverFulfill = false
        expect_join.assertForOverFulfill = false
    
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
    
    func testServer_06_startVideoChat() {
        let expect_call = self.expectation(description: "Expected to get a call request")
        let expect_offer = self.expectation(description: "Expected to get a call offer")
        let expect_hangup = self.expectation(description: "Expected to hangup the offer")
        let expect_connect = self.expectation(description: "Expected to connect to the candidates")
        let expect_closed = self.expectation(description: "Expected to close the call")
        try! self.simulateTextMessage("Start a new video chat to run tests")
        self.simulateVideoCall(call: expect_call, offer: expect_offer, hangup: expect_hangup, connected: expect_connect, closed: expect_closed)

        /// wait until supervisor initiate a call
        waitForExpectations(timeout: 15.0)
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

        do {
            self.sessionManager.chatMessages.removeAll()
            self.sessionManager.onHistoryLoaded = { length in
                XCTAssertEqual(length, 3)
                XCTAssertEqual(self.sessionManager.chatMessages.count, length)
                expect.fulfill()
            }

            try self.sessionManager.loadHistory { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 15.0)
    }

    func testServer_09_deallocate() {
        let expect_deallocation = self.expectation(description: "Expected to delete user and close the session")

        self.sessionManager.onSessionDeallocated = {
            expect_deallocation.fulfill()
        }
        self.sessionManager.deallocateSession()
        self.rtcClient?.disconnect()

        self.sessionManager.disconnect()
        self.sessionManager = Session.initiate()
        waitForExpectations(timeout: 15.0)
    }

    // MARK: - resume

    func testServer_10_resumeSession() {
        let expect_config = self.expectation(description: "Expected to get configs for resuming the session")
        let expect_resume = self.expectation(description: "Expected to continue a session using credentials")
        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { error in
            XCTAssertNil(error)
            expect_config.fulfill()

            do {
                try self.sessionManager.continueSession(credentials: self.credentials) { newCredentials, canResume, error in
                    XCTAssertNil(error)
                    XCTAssertNotNil(newCredentials)
                    /// The new credentials contains only the new session ID
                    XCTAssertEqual(newCredentials?.userID, self.credentials.userID, "The new credentials should come with the same user id")
                    XCTAssertEqual(newCredentials?.userAuth, "", "The new credentials should come with an empty user auth")
                    XCTAssertNotEqual(newCredentials?.sessionID, self.credentials.sessionID, "The new credentials should come with the new session id")

                    XCTAssertTrue(canResume)
                    expect_resume.fulfill()
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        waitForExpectations(timeout: 15.0)
    }

    func testServer_11_retryVideoChat() {
        let expect_call = self.expectation(description: "Expected to get a call request - 2")
        let expect_offer = self.expectation(description: "Expected to get a call offer - 2")
        let expect_hangup = self.expectation(description: "Expected to hangup the offer - 2")
        let expect_connect = self.expectation(description: "Expected to connect to the candidates - 2")
        let expect_closed = self.expectation(description: "Expected to close the call - 2")
        try! self.simulateTextMessage("Start a new video chat again to run tests")
        self.simulateVideoCall(call: expect_call, offer: expect_offer, hangup: expect_hangup, connected: expect_connect, closed: expect_closed)

        /// wait until supervisor initiate a call
        waitForExpectations(timeout: 10.0)
    }

    func testServer_12_reloadHistory() {
        let expect = self.expectation(description: "Expected to fetch all messages after the transfer")
        expect.assertForOverFulfill = false

        do {
            self.sessionManager.chatMessages.removeAll()
            self.sessionManager.onHistoryLoaded = { length in
                XCTAssertEqual(length, 5)
                XCTAssertEqual(self.sessionManager.chatMessages.count, length)
                expect.fulfill()
            }

            try self.sessionManager.loadHistory { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 15.0)
    }

    func testServer_13_setPostAudienceQuestionnaire() {
        let expect = self.expectation(description: "Expected to submit post audience questionnaire")
        let post_answers: [String:AnyHashable] = ["Questionnaire_post_1": "Answer_post_1", "Questionnaire_post_2": "Answer_post_2"]

        do {
            try self.simulateTextMessage("Check the pre/post questionnaires on the sidebar, before you leave the test suite")
            try self.sessionManager.send(type: .metadata, payload: ["data": ["post_answers": post_answers], "time": Date().timeIntervalSince1970]) { error in
                XCTAssertNil(error)
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        wait(for: [expect], timeout: 15.0)
    }

    func testServer_14_deallocate() {
        let expect_close = self.expectation(description: "Expected to delete user and close the session")
        let expect_deallocation = self.expectation(description: "Expected to delete user and close the session")

        do {
            try self.sessionManager.deleteCurrentUser { error in
                self.sessionManager.disconnect()
                XCTAssertNil(error)
                expect_close.fulfill()

                self.sessionManager.onSessionDeallocated = {
                    expect_deallocation.fulfill()
                }
                self.sessionManager.deallocateSession()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 15.0)
    }
}

// MARK: - Helper functions

extension NinchatSDKSwiftAcceptanceTests {
    internal func simulateTextMessage(_ message: String) throws {
        try self.sessionManager.send(message: message, completion: { _ in })
    }

    internal func simulateVideoCall(call: XCTestExpectation, offer: XCTestExpectation, hangup: XCTestExpectation, connected: XCTestExpectation, closed: XCTestExpectation) {
        call.assertForOverFulfill = false
        offer.assertForOverFulfill = false
        hangup.assertForOverFulfill = false

        self.onConnectionStateChange = { client, state in
            debugger("** New State: \(state)")
            XCTAssertNotNil(client)
            if state == .connected {
                try! self.simulateTextMessage("Now hangup to continue running tests")
                connected.fulfill()
            } else if state == .closed {
                closed.fulfill()
            }
        }
        self.onError = { client, error in
            XCTAssertNotNil(client)
            XCTFail("Failed due to the error: \(error)")
        }

        self.sessionManager.onRTCSignal = { type, user, signal in
            XCTAssertNotNil(signal)
            XCTAssertNotNil(user)

            if type == .call {
                XCTAssertNil(signal?.candidate)
                XCTAssertNil(signal?.sdp)

                try! self.sessionManager.send(type: .pickup, payload: ["answer": true]) { error in
                    XCTAssertNil(error)
                }
                call.fulfill()
            }

            if type == .offer {
                try! self.sessionManager.beginICE { error, stunServers, turnServers in
                    XCTAssertNil(error)
                    XCTAssertNotNil(stunServers)
                    XCTAssertNotNil(turnServers)
                    self.rtcClient = NINChatWebRTCClientImpl(sessionManager: self.sessionManager, operatingMode: .callee, stunServers: stunServers, turnServers: turnServers, delegate: self)
                    try! self.rtcClient?.start(with: signal)

                    offer.fulfill()
                }
            }

            if type == .hangup {
                self.rtcClient?.disconnect()
                self.rtcClient = nil
                hangup.fulfill()
            }
        }
    }
}

extension NinchatSDKSwiftAcceptanceTests: NINChatSessionInternalDelegate {
    func log(value: String) {}

    func log(format: String, _ args: CVarArg...) {}

    func onDidEnd() {}

    func onResumeFailed() -> Bool { true }

    func override(imageAsset key: AssetConstants) -> UIImage? { nil }

    func override(colorAsset key: ColorConstants) -> UIColor? { nil }

    func override(questionnaireAsset key: QuestionnaireColorConstants) -> UIColor? { nil }

    func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
        if case let .failure(error) = event.event { self.onEvent?(nil, error); return }
        self.onEvent?(Events(rawValue: event.event.value), nil)
    }
}

extension NinchatSDKSwiftAcceptanceTests: QueueUpdateCapture {
    var desc: String {
        "NinchatSDKSwiftServerInternalTests"
    }
}
