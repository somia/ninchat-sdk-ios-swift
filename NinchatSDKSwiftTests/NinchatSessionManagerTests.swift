//
// Copyright (c) 26.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

// MARK: - Tests

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
        XCTAssertNotNil(sessionManager as NANChatSessionMessenger)
        XCTAssertNotNil(sessionManager as NINChatSessionManagerDelegate)
        XCTAssertNotNil(sessionManager as NINChatSessionManager)
    }
}

// MARK: - PrivateTests

class NinchatSessionManagerPrivateTests: XCTestCase {
    var sessionSwift: NINChatSessionSwift!
    var sessionManager: NINChatSessionManagerImpl!
    
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

    func testMessages_Add() {
        var expectation_index = 0
        var expectation_count = 0
        var expectation_messageID = 0
        var should_fulfill_expectation = false
        var should_fail_closure = false

        let expect = self.expectation(description: "Expected to get add message closure in sorted orders")
        sessionManager.onMessageAdded = { index in
            if should_fail_closure {
                XCTFail("The closure should have not been called")
            }

            XCTAssertEqual(index, expectation_index)
            XCTAssertEqual(self.sessionManager.chatMessages.count, expectation_count)

            XCTAssertNotNil(self.sessionManager.chatMessages.first as? NINChannelMessage)
            XCTAssertEqual((self.sessionManager.chatMessages.first as? NINChannelMessage)?.messageID, "\(expectation_messageID)")

            if should_fulfill_expectation {
                expect.fulfill()
            }
        }

        /// first message
        expectation_index = 0
        expectation_count = 1
        expectation_messageID = 1
        self.simulateAddMessage(id: 1)

        /// next ordered message
        expectation_index = 0
        expectation_count = 2
        expectation_messageID = 3
        self.simulateAddMessage(id: 3)

        /// a message is duplicated, should not be added to the closure
        should_fail_closure = true
        self.simulateAddMessage(id: 3)

        /// oh, some message are missed, let's put them between current chat orders
        expectation_index = 1
        expectation_count = 3
        expectation_messageID = 3
        should_fail_closure = false
        should_fulfill_expectation = true
        self.simulateAddMessage(id: 2)

        waitForExpectations(timeout: 5.0)
    }

    func testMessages_Remove() {
        /// first, add some messages in a correct order
        self.simulateAddMessage(id: 0)
        self.simulateAddMessage(id: 1)
        self.simulateAddMessage(id: 2)
        self.simulateAddMessage(id: 3)
        self.simulateAddMessage(id: 4)

        let expect = self.expectation(description: "The message should have been removed")
        self.sessionManager.onMessageRemoved = { index in
            XCTAssertEqual(index, 3)
            XCTAssertEqual(self.sessionManager.chatMessages.count, 4)

            XCTAssertNotNil(self.sessionManager.chatMessages[3] as? NINChannelMessage)
            XCTAssertNotEqual((self.sessionManager.chatMessages[3] as? NINChannelMessage)?.messageID, "2")

            expect.fulfill()
        }

        /// now, remove one of the messages
        self.simulateRemoveMessage(at: 3) /// message_id = 2
        waitForExpectations(timeout: 5.0)
    }
}

extension NinchatSessionManagerPrivateTests {
    private func simulateAddMessage(id: Int) {
        let user = NINChannelUser(id: "11", realName: "Hassan Shahbazi", displayName: "Hassan", iconURL: "", guest: false)
        let textMessage = NINTextMessage(messageID: "\(id)", textContent: "content", sender: user!, timestamp: Date(), mine: false, attachment: nil)
        self.sessionManager.add(message: textMessage)
    }

    private func simulateRemoveMessage(at index: Int) {
        self.sessionManager.removeMessage(atIndex: index)
    }
}

// MARK: - ClosureHandlersTests

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

    func testBindQueueUpdate() {
        let expect = self.expectation(description: "expect to receive the closure values")
        sessionManager.bindQueueUpdate(closure: { _, _, error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error as! NINExceptions == .mainThread)
            expect.fulfill()

        }, to: self)

        self.simulateChatQueue()
        waitForExpectations(timeout: 1.0)
    }

    func testUnbindQueueUpdate() {
        sessionManager.bindQueueUpdate(closure: { _, _, error in
            XCTFail("The closure is not allowed to be called once it is unbound")
        }, to: self)
        sessionManager.unbindQueueUpdateClosure(from: self)

        let expect = self.expectation(description: "Expected to fulfill the test case")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expect.fulfill()
        }

        self.simulateChatQueue()
        waitForExpectations(timeout: 1.0)
    }
}

extension NinchatSessionManagerClosureHandlersTests {
    private func simulateChatQueue() {
        sessionManager.queueUpdateBoundClosures.forEach {
            $0.value(.audienceEnqueued, "queue", NINExceptions.mainThread)
        }
    }
}

extension NinchatSessionManagerClosureHandlersTests: QueueUpdateCapture {
    var desc: String {
        "NinchatSessionTests"
    }
}
