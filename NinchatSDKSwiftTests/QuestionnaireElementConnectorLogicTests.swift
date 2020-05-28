//
// Copyright (c) 28.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
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
            self.questionnaire_preAudience = AudienceQuestionnaire(from: try openTestFile(), for: "preAudienceQuestionnaire")
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

        let satisfied_1 = connector.areSatisfied(logic: blocks!, forKeyValue: [:])
        XCTAssertFalse(satisfied_1.0)
        XCTAssertNil(satisfied_1.1)

        let satisfied_2 = connector.areSatisfied(logic: blocks!, forKeyValue: ["Epäilys-jatko": "Muut aiheet"])
        XCTAssertTrue(satisfied_2.0)
        XCTAssertNotNil(satisfied_2.1)
        XCTAssertEqual(satisfied_2.1?.target, "Aiheet")
    }

    func test_13_find_configuration() {
        let blocks = connector.findLogicBlocks(for: ["fake"])
        let logic = connector.areSatisfied(logic: blocks!, forKeyValue: ["fake": "fake"]).1
        let configuration = connector.findTargetLogicConfiguration(from: logic!)
        XCTAssertNotNil(configuration.0)
        XCTAssertNotNil(configuration.1)
        XCTAssertEqual(configuration.1, 0)
    }

    func test_14_find_element() {
        let blocks = connector.findLogicBlocks(for: ["fake"])
        let logic = connector.areSatisfied(logic: blocks!, forKeyValue: ["fake": "fake"]).1
        let configuration = connector.findTargetLogicConfiguration(from: logic!).0
        let targetView = connector.findTargetElement(for: configuration!)
        XCTAssertNotNil(targetView.0)
        XCTAssertNotNil(targetView.1)
        XCTAssertEqual(targetView.1, 0)
    }

    func test_15_find_element() {
        let blocks = connector.findLogicBlocks(for: ["Epäilys-jatko"])
        let logic = connector.areSatisfied(logic: blocks!, forKeyValue: ["Epäilys-jatko": "Muut aiheet"]).1
        let configuration = connector.findTargetLogicConfiguration(from: logic!).0
        let targetView = connector.findTargetElement(for: configuration!)
        XCTAssertNotNil(targetView.0)
        XCTAssertNotNil(targetView.1)
        XCTAssertEqual(targetView.1, 0)
    }

    /// Acceptance test
    func test_20_acceptance() {
        let targetElement = connector.findElementAndPageLogic(for: ["Epäilys-jatko": "Muut aiheet"])
        XCTAssertNotNil(targetElement.0)
        XCTAssertNotNil(targetElement.1)

        XCTAssertEqual(targetElement.0?.count, 1)
        XCTAssertNotNil(targetElement.0?.first as? QuestionnaireElementRadio)
        XCTAssertEqual(targetElement.1, 0)
    }
}

extension QuestionnaireElementConnectorLogicTests {
    private func openTestFile() throws -> [String:AnyHashable]? {
        let bundle = Bundle(for: QuestionnaireConverterTests.self)
        if let path = bundle.path(forResource: "questionnaire-mock", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            return jsonResult as? [String:AnyHashable]
        }
        return nil
    }
}
