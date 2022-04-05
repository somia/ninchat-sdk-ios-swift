//
// Copyright (c) 5.4.2022 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class QuestionnaireElementConnectorTests: XCTestCase {
    private var questionnaire_preAudience: AudienceQuestionnaire?
    private lazy var configuration: [QuestionnaireConfiguration]? = {
        self.questionnaire_preAudience?.questionnaireConfiguration
    }()
    private lazy var connector: QuestionnaireElementConnectorImpl = {
        QuestionnaireElementConnectorImpl(configurations: configuration!, style: .conversation)
    }()

    override func setUp() {
        super.setUp()

        do {
            self.questionnaire_preAudience = AudienceQuestionnaire(from: try openAsset(forResource: "questionnaire-mock"), for: "preAudienceQuestionnaire")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_00_initiate() {
        XCTAssertNotNil(questionnaire_preAudience)
        XCTAssertNotNil(configuration)
    }

    /// Acceptance tests
    func test_10_find_configuration() {
        /// Recursion Level: 1
        let target_1 = connector.findConfiguration(label: "Koronavirus", in: self.configuration)
        XCTAssertNotNil(target_1)

        /// Recursion Level: 2
        let target_1_2 = connector.findConfiguration(label: "Koronavirus-jatko", in: self.configuration)
        XCTAssertNotNil(target_1_2)

        /// Logic
        let logic = connector.findConfiguration(label: "Epäilys-Logic1", in: self.configuration)
        XCTAssertNotNil(logic)

        /// Unavailable Configuration
        let unavailable = connector.findConfiguration(label: "un", in: self.configuration)
        XCTAssertNil(unavailable)
        let empty_1 = connector.findConfiguration(label: "", in: self.configuration)
        XCTAssertNil(empty_1)
        let empty_2 = connector.findConfiguration(label: "Koronavirus", in: [])
        XCTAssertNil(empty_2)
        let null = connector.findConfiguration(label: "", in: nil)
        XCTAssertNil(null)
    }
}
