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
        QuestionnaireElementConnectorImpl(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)
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

    func test_10_list() {
        XCTAssertNotNil(connector.logicList)
        XCTAssertGreaterThan(connector.logicList.count, 0)
    }
    
    func test_11_findLogic() {
        let target = connector.findLogicBlocks(for: ["fake"])
        XCTAssertNotNil(target)
        XCTAssertEqual(target?.count, 2)
    }

    func test_12_satisfyLogic() {
        let blocks = connector.findLogicBlocks(for: ["Epäilys-jatko"])

        let satisfied_0 = connector.areSatisfied(logic: blocks!, forAnswers: [:])
        XCTAssertFalse(satisfied_0.0)
        XCTAssertNil(satisfied_0.1)

        let satisfied_1 = connector.areSatisfied(logic: blocks!, forAnswers: ["Epäilys-jatko":""])
        XCTAssertFalse(satisfied_1.0)
        XCTAssertNil(satisfied_1.1)

        let satisfied_2 = connector.areSatisfied(logic: blocks!, forAnswers: ["Epäilys-jatko": "Muut aiheet"])
        XCTAssertTrue(satisfied_2.0)
        XCTAssertNotNil(satisfied_2.1)
        XCTAssertEqual(satisfied_2.1?.target, "Aiheet")
    }

    func test_13_satisfyLogic_regex() {
        let blocks = connector.findLogicBlocks(for: ["wouldRecommendService"])
        let satisfied = connector.areSatisfied(logic: blocks!, forAnswers: ["wouldRecommendService": "1"])
        XCTAssertTrue(satisfied.0)
        XCTAssertNotNil(satisfied.1)
        XCTAssertEqual(satisfied.1?.target, "_complete")
    }

    func test_14_satisfyLogic_complex() {
        let blocks = connector.findLogicBlocks(for: ["temp-btn"])

        let satisfied_1 = connector.areSatisfied(logic: blocks!, forAnswers: ["temp-btn":"Finnish"])
        XCTAssertFalse(satisfied_1.0)
        XCTAssertNil(satisfied_1.1)

        let satisfied_2 = connector.areSatisfied(logic: blocks!, forAnswers: ["temp-btn2":"Finnish"])
        XCTAssertFalse(satisfied_2.0)
        XCTAssertNil(satisfied_2.1)

        let satisfied_3 = connector.areSatisfied(logic: blocks!, forAnswers: ["temp-btn":"Finnish", "temp-btn2":"Finnish"])
        XCTAssertTrue(satisfied_3.0)
        XCTAssertNotNil(satisfied_3.1)
        XCTAssertEqual(satisfied_3.1?.target, "_complete")
    }

    func test_14_find_configuration() {
        let blocks = connector.findLogicBlocks(for: ["fake"])
        let logic = connector.areSatisfied(logic: blocks!, forAnswers: ["fake": "fake", "Koronavirus-jatko": "Muut aiheet"]).1
        let configuration = connector.findTargetLogicConfiguration(from: logic!)
        XCTAssertNotNil(configuration.0)
        XCTAssertNotNil(configuration.1)
        XCTAssertEqual(configuration.1, 0)
    }

    func test_15_find_element() {
        let blocks = connector.findLogicBlocks(for: ["fake"])
        let logic = connector.areSatisfied(logic: blocks!, forAnswers: ["fake": "fake", "Koronavirus-jatko": "Muut aiheet"]).1
        let configuration = connector.findTargetLogicConfiguration(from: logic!).0
        let targetView = connector.findTargetElement(for: configuration!)
        XCTAssertNotNil(targetView.0)
        XCTAssertNotNil(targetView.1)
        XCTAssertEqual(targetView.1, 0)
    }

    func test_16_find_element() {
        let blocks = connector.findLogicBlocks(for: ["Epäilys-jatko"])
        let logic = connector.areSatisfied(logic: blocks!, forAnswers: ["Epäilys-jatko": "Muut aiheet"]).1
        let configuration = connector.findTargetLogicConfiguration(from: logic!).0
        let targetView = connector.findTargetElement(for: configuration!)
        XCTAssertNotNil(targetView.0)
        XCTAssertNotNil(targetView.1)
        XCTAssertEqual(targetView.1, 0)
    }

    /// Acceptance test
    func test_20_acceptance() {
        let targetElement = connector.findElementAndPageLogic(for: ["Riskiryhmät-jatko": "Muut aiheet", "condition1": "satisfied"], in: ["Riskiryhmät-jatko": "Muut aiheet", "condition1": "satisfied"])
        XCTAssertNotNil(targetElement.0)
        XCTAssertNotNil(targetElement.1)

        XCTAssertEqual(targetElement.0?.count, 1)
        XCTAssertNotNil(targetElement.0?.first as? QuestionnaireElementRadio)
        XCTAssertEqual(targetElement.1, 0)
    }

    func test_21_acceptance() {
        let expect = self.expectation(description: "Expected to reach `_complete` target")
        expect.assertForOverFulfill = false

        connector.onCompleteTargetReached = { logic, redirect, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNotNil(logic)
            XCTAssertNil(redirect)
            expect.fulfill()
        }
        let targetElement = connector.findElementAndPageLogic(for: ["temp-btn":"Finnish"], in: ["Riskiryhmät-jatko": "Muut aiheet", "condition1": "satisfied", "temp-btn":"Finnish", "temp-btn2":"Finnish"])
        XCTAssertNil(targetElement.0)
        XCTAssertNotNil(targetElement.1)
        XCTAssertEqual(targetElement.1, -1)

        waitForExpectations(timeout: 2.0)
    }
}
