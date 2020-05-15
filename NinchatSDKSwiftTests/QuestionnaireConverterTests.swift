//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class QuestionnaireConverterTests: XCTestCase {
    var questionnaire_preAudience: AudienceQuestionnaire?

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
        XCTAssertNotNil(questionnaire_preAudience?.questionnaireConfiguration!)
    }

    func test_01_converter_text() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.first?.elements?.filter({ $0.element == .text })
        let views = converter.elements.first?.filter({ ($0 as? QuestionnaireElementText) != nil })
        XCTAssertNotNil(elements)
        XCTAssertNotNil(views)
        XCTAssertEqual(elements?.count, views?.count)

        let configuration = elements![0]
        let view = views![0]
        XCTAssertEqual(view.configuration, configuration)
    }

    func test_02_converter_select() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.first?.elements?.filter({ $0.element == .select })
        let views = converter.elements.first?.filter({ ($0 as? QuestionnaireElementSelect) != nil })
        XCTAssertNotNil(elements)
        XCTAssertNotNil(views)
        XCTAssertEqual(elements?.count, views?.count)

        let configuration = elements![0]
        let view = views![0]
        XCTAssertEqual(view.configuration, configuration)
    }

    func test_03_converter_radio() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.first?.elements?.filter({ $0.element == .radio })
        let views = converter.elements.first?.filter({ ($0 as? QuestionnaireElementRadio) != nil })
        XCTAssertNotNil(elements)
        XCTAssertNotNil(views)
        XCTAssertEqual(elements?.count, views?.count)

        let configuration = elements![0]
        let view = views![0]
        XCTAssertEqual(view.configuration, configuration)
    }

    func test_04_converter_textArea() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.first?.elements?.filter({ $0.element == .textarea })
        let views = converter.elements.first?.filter({ ($0 as? QuestionnaireElementTextArea) != nil })
        XCTAssertNotNil(elements)
        XCTAssertNotNil(views)
        XCTAssertEqual(elements?.count, views?.count)

        let configuration = elements![0]
        let view = views![0]
        XCTAssertEqual(view.configuration, configuration)
    }

    func test_05_converter_textField() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.first?.elements?.filter({ $0.element == .input && $0.type == .text })
        let views = converter.elements.first?.filter({ ($0 as? QuestionnaireElementTextField) != nil })
        XCTAssertNotNil(elements)
        XCTAssertNotNil(views)
        XCTAssertEqual(elements?.count, views?.count)

        let configuration = elements![0]
        let view = views![0]
        XCTAssertEqual(view.configuration, configuration)
    }

    func test_06_converter_checkbox() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.first?.elements?.filter({ $0.element == .checkbox })
        let views = converter.elements.first?.filter({ ($0 as? QuestionnaireElementCheckbox) != nil })
        XCTAssertNotNil(elements)
        XCTAssertNotNil(views)
        XCTAssertEqual(elements?.count, views?.count)

        let configuration = elements![0]
        let view = views![0]
        XCTAssertEqual(view.configuration, configuration)
    }
}

extension QuestionnaireConverterTests {
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