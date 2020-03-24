//
// Copyright (c) 21.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import XCTest
@testable import NinchatSDKSwift

final class NINFullScreenViewModelTests: XCTestCase {
    var viewModel: NINFullScreenViewModelImpl!
    
    func test_viewModel() {
        viewModel = NINFullScreenViewModelImpl(delegate: nil)
        
        /// Due to restrictions of iOS simulator, it is not possible to save images into simulator's gallery
        /// as it needs photo access permissions and cannot grant for a framework project (nothing will be installed on the simulator)
        let expect = self.expectation(description: "Expected to save image without any errors")
        viewModel.download(image: UIImage(named: "icon_face_happy", in: Bundle.SDKBundle, compatibleWith: nil)!) { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}