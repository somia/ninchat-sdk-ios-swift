//
//  UIMigrationTests.swift
//  NinchatSDKSwiftTests
//
//  Created by Hassan Shahbazi on 9.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

class UIMigrationTests: XCTestCase {
    var button: UIButton!
    
    override func setUp() { }

    override func tearDown() { }

    func testUIButtonAction() {
        let expt = expectation(description: "The `UIButton` action is fulfilled")
        button = NINButton(frame: .zero, touch: { button in
            XCTAssertNotNil(button as? NINButton)
            expt.fulfill()
        })
        button.sendActions(for: .touchUpInside)
        
        waitForExpectations(timeout: 0.2, handler: nil)
    }
}
