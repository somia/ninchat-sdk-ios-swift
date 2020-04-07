//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

class CoordinatorTests: XCTestCase {
    let navigationController = UINavigationController()
    let session = NINChatSessionSwift(configKey: "")
    var coordinator: NINCoordinator!
    
    override func setUp() {
        coordinator = NINCoordinator(with: session)
    }

    override func tearDown() { }
    
    func testStoryboardAccess() {
        let joinViewController: NINQueueViewController = coordinator.storyboard.instantiateViewController()
        XCTAssertNotNil(joinViewController)
        
        let initialViewController: NINInitialViewController = coordinator.storyboard.instantiateViewController()
        XCTAssertNotNil(initialViewController)
    }
    
    func testStartNINChatSessionViewController() {
        let joinOptions = coordinator.start(with: nil, resumeSession: false, within: navigationController)
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNotNil(joinOptions as? NINInitialViewController)
        
        let initialChat = coordinator.start(with: "default", resumeSession: false, within: navigationController)
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNil(initialChat as? NINQueueViewController, "The result is nil since there is not any audience queue from the server")

        let chatView = coordinator.start(with: nil, resumeSession: true, within: navigationController)
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNotNil(chatView as? NINChatViewController)
    }
    
    func testInitialViewController_automaticJoin() {
        let vcNil = coordinator.joinAutomatically(for: "")
        XCTAssertNil(vcNil)
        
        let vc = coordinator.joinDirectly(to: Queue(queueID: "id", name: "name"))
        XCTAssertNotNil(vc)
    }

    func testInitialViewController_queueOptions() {
        let vc = coordinator.showJoinOptions() as? NINInitialViewController
        XCTAssertNotNil(vc)
        XCTAssertNotNil(vc?.onQueueActionTapped)
    }
    
    func testChatViewController() {
        let vc = coordinator.showChatViewController() as? NINChatViewController
        XCTAssertNotNil(vc)
    }
    
    func testRatingViewController() {
        let vc = coordinator.showRatingViewController() as? NINRatingViewController
        XCTAssertNotNil(vc)
    }
}
