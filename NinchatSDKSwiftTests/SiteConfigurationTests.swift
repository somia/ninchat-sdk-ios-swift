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
            siteConfiguration = SiteConfigurationImpl(configuration: try openAsset(forResource: "site-configuration-mock"), environments: ["fi-restart", "fi"])
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

    func test_11_postQuestionnaire_style() {
        XCTAssertEqual(siteConfiguration?.preAudienceQuestionnaireStyle, .conversation)
        XCTAssertEqual(siteConfiguration?.postAudienceQuestionnaireStyle, .conversation)
    }

    func test_12_audienceQuestionnaire_name_avatar() {
        XCTAssertNotNil(siteConfiguration?.audienceQuestionnaireAvatar as? String)
        XCTAssertEqual(siteConfiguration?.audienceQuestionnaireUserName, "Mielen-botti")
    }

    func test_20_envPriority() {
        XCTAssertNil(siteConfiguration?.sendButtonTitle, "The key is missing from all given environments + default")
        XCTAssertEqual(siteConfiguration?.userName, "Asiakas (öäå)", "The key should be read from 'default' since neither 'fi' nor 'fi-restart' contains that.")
        XCTAssertEqual(siteConfiguration?.audienceRealm, "5lmphjc200m3g", "They key should be read from 'fi-restart' since 'fi' doesn't contain that.")
        XCTAssertEqual(siteConfiguration?.welcome, "fi", "The key is present in all env, but it should be read from 'fi' according to the reversed sort of the given array")
    }
}

