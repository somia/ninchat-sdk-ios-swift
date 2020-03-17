//
// Copyright (c) 21.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

final class NINQueueViewModelTests: NinchatViewModelTestCase {
    var viewModel: NINQueueViewModel!
    
    func test_viewModel() {
        let queue = Queue(queueID: Session.suiteQueue, name: "UnitTest")
        viewModel = NINQueueViewModelImpl(sessionManager: super.sessionManager, queue: queue, delegate: nil)
        
        let expect_updateText = self.expectation(description: "Expected to get text updates")
        viewModel.onInfoTextUpdate = { text in
            XCTAssertEqual(text, "Jonotat jonossa UnitTest seuraavana vuorossa.")
            expect_updateText.fulfill()
        }
        
        let expect_join = self.expectation(description: "Expected to get informed on queue join")
        viewModel.onQueueJoin = { error in
            XCTAssertNil(error)
            expect_join.fulfill()
        }
        
        viewModel.connect()
    
        /// The test needs a manual interaction from server to fulfills all expectations
        waitForExpectations(timeout: 30.0)
    }
}