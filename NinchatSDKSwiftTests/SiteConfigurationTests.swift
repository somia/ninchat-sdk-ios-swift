//
// Copyright (c) 2.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class SiteConfigurationTests: XCTestCase {
    var siteConfiguration: SiteConfiguration?

    override func setUp() {
        super.setUp()

        do {
            siteConfiguration = SiteConfigurationImpl(configuration: try openAsset(forResource: "site-configuration-mock"), environments: ["default"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_00_initialization() {
        XCTAssertNotNil(siteConfiguration)
    }

    func test_10_preQuestionnaire() {
        XCTAssertNotNil(siteConfiguration?.preAudienceQuestionnaire)
        XCTAssertGreaterThan(siteConfiguration?.preAudienceQuestionnaire?.count ?? 0, 0)
    }

    func test_11_preAnswers() {
        let preAnswers = siteConfiguration?.preAnswers
        XCTAssertNotNil(preAnswers)

        let answer1 = preAnswers?["Phone"]
        XCTAssertNotNil(answer1)
        XCTAssertEqual(answer1, "+358123456789")
    }
}

