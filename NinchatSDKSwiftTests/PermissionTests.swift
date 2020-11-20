//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class PermissionTests: XCTestCase {
    func test_permissions_photoLibrary() {
        let expect = self.expectation(description: "Expected to get denied permissions")
        Permission.grantPermission(.devicePhotoLibrary) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .permissionDenied)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func test_permissions_camera() {
        let expect = self.expectation(description: "Expected to get denied permissions")
        Permission.grantPermission(.deviceCamera) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func test_permissions_microphone() {
        let expect = self.expectation(description: "Expected to get denied permissions")
        Permission.grantPermission(.deviceMicrophone) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func test_permissions_multiple() {
        let expect = self.expectation(description: "Expected to get all permissions with the same errors")
        Permission.grantPermission(.devicePhotoLibrary, .deviceMicrophone, .deviceCamera) { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .permissionDenied)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
}
