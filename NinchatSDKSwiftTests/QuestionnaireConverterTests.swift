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

        if let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type == .group }).filter({ $0.elements?.filter({ $0.element == .text }).count ?? 0 > 0 }), elements.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementText }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(elements)
            XCTAssertNotNil(views)
            XCTAssertGreaterThanOrEqual(elements.count, views!.count)

            let configuration = elements[0]
            let view = views![0]
            XCTAssertEqual(view.configuration, configuration)
        }

        if let element = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type != .group }).filter({ $0.element == .text }), element.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementText }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(element)
            XCTAssertNotNil(views)

            let configuration = element[0]
            let view = views![0]
            XCTAssertEqual(view.configuration, configuration)
        }
    }

    func test_02_converter_select() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        if let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type == .group }).filter({ $0.elements?.filter({ $0.element == .select }).count ?? 0 > 0 }), elements.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementSelect }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(elements)
            XCTAssertNotNil(views)
            XCTAssertGreaterThanOrEqual(elements.count, views!.count)
        }

        if let element = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type != .group }).filter({ $0.element == .select }), element.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementSelect }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(element)
            XCTAssertNotNil(views)
        }
    }

    func test_03_converter_radio() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        if let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type == .group }).filter({ $0.elements?.filter({ $0.element == .radio }).count ?? 0 > 0 }), elements.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementRadio }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(elements)
            XCTAssertNotNil(views)
            XCTAssertGreaterThanOrEqual(elements.count, views!.count)
        }

        if let element = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type != .group }).filter({ $0.element == .radio }), element.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementRadio }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(element)
            XCTAssertNotNil(views)
        }
    }

    func test_04_converter_textArea() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        if let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type == .group }).filter({ $0.elements?.filter({ $0.element == .textarea }).count ?? 0 > 0 }), elements.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementTextArea }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(elements)
            XCTAssertNotNil(views)
            XCTAssertGreaterThanOrEqual(elements.count, views!.count)
        }

        if let element = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.type != .group }).filter({ $0.element == .textarea }), element.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementTextArea }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(element)
            XCTAssertNotNil(views)
        }
    }

    func test_05_converter_textField() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        if let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.elements?.filter({ $0.element == .input && $0.type == .text }).count ?? 0 > 0 }), elements.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementTextField }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(elements)
            XCTAssertNotNil(views)
            XCTAssertGreaterThanOrEqual(elements.count, views!.count)
        }

        if let element = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.element == .input }), element.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementTextField }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(element)
            XCTAssertNotNil(views)
        }
    }

    func test_06_converter_checkbox() {
        let converter = QuestionnaireElementConverter(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)

        if let elements = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.elements?.filter({ $0.element == .checkbox }).count ?? 0 > 0 }), elements.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementCheckbox }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(elements)
            XCTAssertNotNil(views)
            XCTAssertGreaterThanOrEqual(elements.count, views!.count)
        }

        if let element = self.questionnaire_preAudience?.questionnaireConfiguration?.filter({ $0.element == .checkbox }), element.count > 0 {
            let views = converter.elements.compactMap({ $0.filter({ $0 is QuestionnaireElementCheckbox }) }).first(where: { $0.count > 0 })
            XCTAssertNotNil(element)
            XCTAssertNotNil(views)
        }
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