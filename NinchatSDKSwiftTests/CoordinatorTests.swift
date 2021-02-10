//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

class CoordinatorTests: XCTestCase {
    let navigationController = UINavigationController()
    let session = NINChatSession(configKey: "")
    var coordinator: NINCoordinator!
    

    override func setUp() {
        coordinator = NINCoordinator(with: session.sessionManager, delegate: session.internalDelegate) { }
    }

    override func tearDown() { }
    
    func testStoryboardAccess() {
        let joinViewController: NINQueueViewController = coordinator.storyboard.instantiateViewController()
        XCTAssertNotNil(joinViewController)
        
        let initialViewController: NINInitialViewController = coordinator.storyboard.instantiateViewController()
        XCTAssertNotNil(initialViewController)
    }
    
    func testLazyVariables() {
        XCTAssertNotNil(coordinator.queueViewController)
        XCTAssertNotNil(coordinator.chatViewController)
        XCTAssertNotNil(coordinator.ratingViewController)
    }

    func testStartNINChatSessionViewController() {
        let joinOptions = coordinator.start(with: nil, resume: nil, within: navigationController)
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNotNil(joinOptions as? NINInitialViewController)
        
        let initialChat = coordinator.start(with: "default", resume: nil, within: navigationController)
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNil(initialChat as? NINQueueViewController, "The result is nil since there is not any audience queue from the server")

        let chatView = coordinator.start(with: nil, resume: .toChannel, within: navigationController)
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNotNil(chatView as? NINQueueViewController)
    }
}
