//
// Copyright (c) 14.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

class NinchatSDKSwiftServerMessengerTests: NinchatXCTestCase {
    
    func testServer_0_updateWriting() {
        let expect = self.expectation(description: "Expected to update writing status smoothly")
        do {
            try self.sessionManager.update(isWriting: true) { error in
                XCTAssertNil(error)
                sleep(2) /// let the supervisor check the result on the panel
                
                /// Take the writing status back to default
                try? self.sessionManager.update(isWriting: false) { error in
                    XCTAssertNil(error)
                    expect.fulfill()
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 15.0)
    }

    func testServer_1_sendTextMessage() {
        let expect = self.expectation(description: "Expected to send a text message")
        do {

            self.sessionManager.onMessageAdded = { _ in
                expect.fulfill()
            }
            try self.sessionManager.send(message: "The first message from iOS SDK Swift") { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    
        waitForExpectations(timeout: 5.0)
    }
    
    func testServer_2_sendAttachment() {
        let expect = self.expectation(description: "Expected to send an image")
        do {
            let image = UIImage(named: "icon_face_happy", in: Bundle.SDKBundle, compatibleWith: nil)?.pngData()
            XCTAssertNotNil(image)

            self.sessionManager.onMessageAdded = { _ in
                expect.fulfill()
            }
            try self.sessionManager.send(attachment: "attachment", data: image!) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    
        waitForExpectations(timeout: 5.0)
    }

    func testServer_3_sendExtraText() {
        let expect = self.expectation(description: "Expected to send a text message")
        do {

            self.sessionManager.onMessageAdded = { _ in
                expect.fulfill()
            }
            try self.sessionManager.send(message: "The next message from iOS SDK Swift") { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    
        waitForExpectations(timeout: 5.0)
    }

    func testServer_4_loadHistory_singleMessage() {
        let expect = self.expectation(description: "Expected to get lost message from the server")

        do {
            /// Clear attachment message from the cache
            self.sessionManager.chatMessages.remove(at: 1)

            self.sessionManager.onMessageAdded = { _ in
                XCTFail("Should not call this closure in case of history loading")
            }
            self.sessionManager.onHistoryLoaded = { length in
                XCTAssertEqual(length, 3)
                XCTAssertEqual(self.sessionManager.chatMessages.filter({ $0 is ChannelMessage }).count, length)
                expect.fulfill()
            }

            /// Load the history
            try self.sessionManager.loadHistory { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    
        waitForExpectations(timeout: 15.0)
    }

    func testServer_5_sendMultipleAttachments() {
        let expect = self.expectation(description: "Expected to send images")
        expect.expectedFulfillmentCount = 7

        self.sessionManager.onMessageAdded = nil
        self.sessionManager.onHistoryLoaded = nil
        ["chat_bubble_right", "chat_bubble_left", "chat_bubble_right_series", "chat_bubble_right_series", "chat_bubble_left", "chat_bubble_right", "chat_background_pattern"].forEach { name in
            let image = UIImage(named: name, in: .SDKBundle, compatibleWith: nil)?.pngData()
            XCTAssertNotNil(image)

            try? self.sessionManager.send(attachment: "attachment_\(name)", data: image!) { error in
                XCTAssertNil(error)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 5.0)
    }

    func testServer_6_loadHistory_allMessages() {
        let expect = self.expectation(description: "Expected to fetch all messages from the server")

        do {
            /// Clear all cached messages
            self.sessionManager.chatMessages.removeAll()

            /// Load the history
            self.sessionManager.onHistoryLoaded = { length in
                XCTAssertEqual(length, 10)
                XCTAssertEqual(self.sessionManager.chatMessages.filter({ $0 is ChannelMessage }).count, length)
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
}
