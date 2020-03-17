//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class VideoThumbnailManagerTests: XCTestCase {
    /// TODO: Find an online stable URL
    let videoURL = "https://ninchat-file-test-eu-central-1.s3.amazonaws.com/f/706qec8f00ib8/79s91rbm007n8/IMG_0071.MP4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA56FKNNN7O3J4GU4P%2F20200317%2Feu-central-1%2Fs3%2Faws4_request&X-Amz-Date=20200317T165645Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEL7%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDGV1LWNlbnRyYWwtMSJGMEQCICllO3u3u1MCdiLsxcHsbIZE4BOE6TAmUDw9odmzNoA6AiBKpCU6D1ow%2B9TYEvu7h0kAyk%2Bj%2F%2FGBs7kFs1TEIj9XYSrDAwin%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAAaDDk1ODEzNTEwMjMzNCIM2kjpFa8p8o6q2TFiKpcDjTpoyeMtizz2ghar7p7vO%2FC0Vnx4gEM2s%2BvYmmBok9K4oES8g47B3F8XRBLhhP365AWLK4k0YAk8gMa3pfcwTiL9t9vw%2BQrfj3YwlcEjdjMi9ziAmJenOK6QRgojRlnIGoukb%2FAb6z%2FMkzrGKRtp2sIlHaS299Q0dJGSDhU9pQRt5So20%2Ft3zFqMtvY8FG8cIzq3gNqFByp2mozjTlID%2BraYz%2BxPAslhivdK1FXMJiRof6TNgOhtXn8aW%2FqNXu67bpRNveG5rIQtGK0pkfpNLaiBCY%2F5f4%2BSLWL%2FT1MAM5rRpfl1bqwR0FhmmBmDZPLS0YTYK%2Blu0gOhmh6OJ%2BwTykD2Dat8gyCkUB7wyIrTY2feFzZKclax4vpi%2BQ16WDR37JLOgetR%2Bf20rjpAxdPRTQL5aevZZnOmRdZEY5rxFwqJr7qkmLJ%2B2ECfR%2F6ex9LqHpCefYWa1dy5S5fsC2w1onXVth%2BnVUC4Bmm69zm9YIGIpyl9UCrfs7PMYmTpFpLkkT7Fdo8F4h6vl3HkDz3FXiHRCNP9uRgwq6rD8wU67AHMz0UtgqsG2W0vib4AQoWmegOOOdFYmpD86%2FHWR0zwTdzwHlOLrNU6BoI7eIuAajt3Dfymb2S1O3fwBB4eqOfD6ek%2BwXSy936ftoiuxmuPHr%2BK4ARvOlezck68BMb01O2atG0U4l0zMq8ji%2BJtsQItPyr%2FsTlfKQoMIAgEBaDa2vBXdyLOw3R833XHZrgaiUNwhPs94KA95cTv11%2BB%2BSwHqnWDPduU2lbxcH7uzFio%2FuQ5qWgxht0oJgpODSCWzn%2BbylqVy7DDiYWfjh4ozBlaRM5Pu0GHkWEE6HH9nsprT6J7sOnuUTknqJBm5Q%3D%3D&X-Amz-Signature=8f5ac4f1f93d6195399e9e8b7ece3014bad265e2bfe06f5ca9e248235b331245"
    
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
