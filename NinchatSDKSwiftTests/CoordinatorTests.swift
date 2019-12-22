//
//  CoordinatorTests.swift
//  NinchatSDKSwiftTests
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

class CoordinatorTests: XCTestCase {
    let session = NINChatSessionSwift(configKey: "")
    var coordinator: NINCoordinator!
    
    override func setUp() {
        coordinator = NINCoordinator(with: session)
    }

    override func tearDown() {}
    
    func testStoryboardAccess() {
        let joinViewController: NINQueueViewController = coordinator.storyboard.instantiateViewController()
        XCTAssertNotNil(joinViewController)
        
        let initialViewController: NINInitialViewController = coordinator.storyboard.instantiateViewController()
        XCTAssertNotNil(initialViewController)
    }
    
    func testStartNINChatSessionViewController() {
        let joinOptions = coordinator.start(with: nil, within: UINavigationController())
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNotNil(joinOptions as? NINInitialViewController)
        
        let initialChat = coordinator.start(with: "default", within: UINavigationController())
        XCTAssertNotNil(coordinator.navigationController)
        XCTAssertNil(initialChat as? NINQueueViewController)
    }
    
    func testInitialViewController_automaticJoin() {
        let vcNil = coordinator.joinAutomatically(for: "")
        XCTAssertNil(vcNil)
        
        let vc = coordinator.joinDirectly(to: NINQueue(id: "id", andName: "name"))
        XCTAssertNotNil(vc)
    }

    func testInitialViewController_queueOptions() {
        let vc = coordinator.showJoinOptions() as? NINInitialViewController
        XCTAssertNotNil(vc)
        XCTAssertEqual(vc?.session, session)
    }
    
    func testChatViewController() {
        let vc = coordinator.showChatViewController() as? NINChatViewController
        XCTAssertNotNil(vc)
        XCTAssertEqual(vc?.session, session)
    }
}
