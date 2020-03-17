//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class VideoThumbnailManagerTests: XCTestCase {
    /// TODO: Find an online stable URL
    let videoURL = ""
    
    func test_video_thumbnail() {
        let expect_online = self.expectation(description: "Expected to get thumbnail without any errors from the URL")
        let expect_cache = self.expectation(description: "Expected to get thumbnail without any errors from the cache")
    
        let thumbnailManager = VideoThumbnailManager()
        thumbnailManager.fetchVideoThumbnail(fromURL: self.videoURL) { error, fromCache, image in
            XCTAssertNil(error)
            XCTAssertFalse(fromCache)
            XCTAssertNotNil(image)
    
            expect_online.fulfill()
    
            thumbnailManager.fetchVideoThumbnail(fromURL: self.videoURL) { error, fromCache, image in
                XCTAssertNil(error)
                XCTAssertTrue(fromCache)
                XCTAssertNotNil(image)
        
                expect_cache.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20.0)
    }
}
