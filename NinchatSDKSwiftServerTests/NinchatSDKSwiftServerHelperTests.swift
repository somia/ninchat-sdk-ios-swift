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
        let translate1 = self.sessionManager.translate(key: "Join audience queue {{audienceQueue.queue_attrs.name}}", formatParams: ["audienceQueue.queue_attrs.name":"UnitTest"])
        XCTAssertNotNil(translate1)
        XCTAssertEqual(translate1, "Join audience queue UnitTest")
        
        let translate2 = self.sessionManager.translate(key: "Audience in queue {{queue}} accepted", formatParams: ["queue":"UnitTest"])
        XCTAssertNotNil(translate2)
        XCTAssertEqual(translate2, "Audience in queue UnitTest accepted")
    }
}
