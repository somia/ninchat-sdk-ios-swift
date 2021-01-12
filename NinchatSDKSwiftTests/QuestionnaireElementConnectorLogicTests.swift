//
// Copyright (c) 28.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//


import XCTest
import AnyCodable
@testable import NinchatSDKSwift

final class QuestionnaireElementConnectorLogicTests: XCTestCase {
    private var questionnaire_preAudience: AudienceQuestionnaire?
    private lazy var configuration: QuestionnaireConfiguration? = {
        self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Aiheet" })
    }()
    private lazy var connector: QuestionnaireElementConnectorImpl = {
        QuestionnaireElementConnectorImpl(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!, style: .conversation)
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
        XCTAssertNotNil(questionnaire_preAudience?.questionnaireConfiguration)
        XCTAssertNotNil(configuration)
    }

    /// Acceptance test
    func test_20_acceptance() {
        let block = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Riskiryhmät-Logic2" })?.logic
        XCTAssertNotNil(block)

        let targetElement = connector.findElementAndPageLogic(logic: block!, in: ["Riskiryhmät-jatko": "Muut aiheet", "condition1": "satisfied"], autoApply: false, performClosures: false)
        XCTAssertNotNil(targetElement.0)
        XCTAssertNotNil(targetElement.1)

        XCTAssertEqual(targetElement.0?.count, 1)
        XCTAssertNotNil(targetElement.0?.first as? QuestionnaireElementRadio)
        XCTAssertEqual(targetElement.1, 0)
    }

    func test_21_acceptance() {
        let block = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "start-Logic" })?.logic
        XCTAssertNotNil(block)

        let expect = self.expectation(description: "Expected to reach `_complete` target")
        connector.onCompleteTargetReached = { logic, redirect, autoApply in
            XCTAssertFalse(autoApply)
            XCTAssertNotNil(logic)
            XCTAssertNil(redirect)
            expect.fulfill()
        }

        let targetElement_1 = connector.findElementAndPageLogic(logic: block!, in: ["Riskiryhmät-jatko": "Muut aiheet", "condition1": "satisfied", "temp-btn":"Finnish", "temp-btn2":"Finnish"], autoApply: false, performClosures: true)
        XCTAssertNil(targetElement_1.0)
        XCTAssertNotNil(targetElement_1.1)
        XCTAssertEqual(targetElement_1.1, -1)

        let targetElement_2 = connector.findElementAndPageLogic(logic: block!, in: ["Riskiryhmät-jatko": "Muut aiheet", "condition1": "satisfied", "temp-btn":"Finnish", "temp-btn2":"Finnish"], autoApply: false, performClosures: false)
        XCTAssertNil(targetElement_2.0)
        XCTAssertNil(targetElement_2.1)

        waitForExpectations(timeout: 2.0)
    }

    func test_22_acceptance() {
        let block = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "logic" })?.logic
        XCTAssertNotNil(block)

        let targetElement = connector.findElementAndPageLogic(logic: block!, in: ["Riskiryhmät-jatko": "Muut aiheet", "BOOL_logic": true], autoApply: false, performClosures: false)
        XCTAssertNotNil(targetElement.0)
        XCTAssertNotNil(targetElement.1)

        XCTAssertEqual(targetElement.0?.count, 2)
        XCTAssertNotNil(targetElement.0?[0] as? QuestionnaireElementText)
        XCTAssertNotNil(targetElement.0?[1] as? QuestionnaireElementRadio)
        XCTAssertEqual(targetElement.1, 1)
    }
}
