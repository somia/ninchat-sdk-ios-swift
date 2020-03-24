//
// Copyright (c) 16.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class NinchatSDKSwiftServerHelperTests: NinchatXCTestCase {
    
    func testServer_describeFile() {
        let expect = self.expectation(description: "Expected to describe file with id")
    
        self.sessionManager.onMessageAdded = { index in
            /// Wait to get the file added to cache
            guard let message = self.sessionManager.chatMessages[index] as? TextMessage else { return }
            let attachment = message.attachment
            XCTAssertNotNil(attachment)
            
            do {
                try self.sessionManager.describe(file: attachment?.fileID ?? "") { error, info in
                    XCTAssertNil(error)
                    XCTAssertNotNil(info)
                    expect.fulfill()
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    
        self.simulateSendAttachment()
        waitForExpectations(timeout: 15.0)
    }
    
    func testServer_translate() {
        let translate = self.sessionManager.translate(key: "Join audience queue {{audienceQueue.queue_attrs.name}}", formatParams: ["audienceQueue.queue_attrs.name":"UnitTest"])
        XCTAssertNotNil(translate)
        XCTAssertEqual(translate, "Mene jonoon UnitTest")
    }
}