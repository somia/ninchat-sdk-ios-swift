//
// Copyright (c) 14.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import XCTest
import NinchatSDK
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
            try self.sessionManager.send(message: "The first message from iOS SDK Swift") { error in
                XCTAssertNil(error)
                expect.fulfill()
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
            
            try self.sessionManager.send(attachment: "attachment", data: image!) { error in
                XCTAssertNil(error)
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    
        waitForExpectations(timeout: 5.0)
    }

    func testServer_3_sendExtraText() {
        let expect = self.expectation(description: "Expected to send a text message")
        do {
            try self.sessionManager.send(message: "The next message from iOS SDK Swift") { error in
                XCTAssertNil(error)
                expect.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    
        waitForExpectations(timeout: 5.0)
    }
    
    func testServer_4_loadHistory() {
        let expect = self.expectation(description: "Expected to update writing status smoothly")
        do {
            /// Clear attachment message from the cache
            self.sessionManager.chatMessages.remove(at: 1)
            
            /// Set listener, check that the message inserted in the right order
            self.sessionManager.onMessageAdded = { index in
                XCTAssertEqual(index, 1)
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
}