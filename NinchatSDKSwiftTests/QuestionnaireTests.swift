//
// Copyright (c) 11.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class QuestionnaireTests: XCTestCase {
    var questionnaire_raw: [String: AnyHashable]?
    var questionnaire_preAudience: AudienceQuestionnaire?

    override func setUp() {
        super.setUp()

        do {
            self.questionnaire_raw = try openTestFile()
            self.questionnaire_preAudience = AudienceQuestionnaire(from: questionnaire_raw, for: "preAudienceQuestionnaire")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_00_openFile() {
        XCTAssertNotNil(questionnaire_raw)
        XCTAssertTrue(questionnaire_raw?["preAudienceQuestionnaire"] is Array<[String: AnyHashable]>)
    }

    func test_01_parseConfiguration() {
        XCTAssertNotNil(self.questionnaire_preAudience)
        XCTAssertNotNil(self.questionnaire_preAudience?.questionnaireConfiguration)
        XCTAssertGreaterThan(self.questionnaire_preAudience!.questionnaireConfiguration!.count, 0)
    }

    func test_02_equableConfiguration() {
        let configuration = self.questionnaire_preAudience!.questionnaireConfiguration?.first(where: { $0.name == "Aiheet" })
        let elements = self.questionnaire_preAudience!.questionnaireConfiguration?.first(where: { $0.name == "Aiheet" })?.elements
        XCTAssertTrue(configuration?.elements == elements)
    }

    func test_10_parseConfiguration_element() {
        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Aiheet" }) {
            XCTAssertNil(questionnaireItem.elements)
            XCTAssertNotNil(questionnaireItem.options)
            XCTAssertNotNil(questionnaireItem.buttons)
            XCTAssertNotNil(questionnaireItem.redirects)
        } else {
            XCTFail("Failed to get ´Aiheet´ questionnaire item")
        }
    }

    func test_11_parseConfiguration_elements() {
        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Koronavirus" }) {
            XCTAssertNotNil(questionnaireItem.elements)
            XCTAssertNil(questionnaireItem.options)
            XCTAssertNotNil(questionnaireItem.buttons)
            XCTAssertNil(questionnaireItem.redirects)
            XCTAssertEqual(questionnaireItem.type, .group)

            if let textElement = questionnaireItem.elements?.first(where: { $0.element == .text }) {
                XCTAssertNotNil(textElement.name)
                XCTAssertNotNil(textElement.label)
                XCTAssertNil(textElement.redirects)
                XCTAssertNil(textElement.elements)
            } else {
                XCTFail("Failed to get ´Koronavirus´ text elements")
            }

            if let radioElement = questionnaireItem.elements?.first(where: { $0.element == .radio }) {
                XCTAssertNotNil(radioElement.name)
                XCTAssertNotNil(radioElement.label)
                XCTAssertNotNil(radioElement.options)
                XCTAssertTrue(radioElement.required ?? false)
            } else {
                XCTFail("Failed to get ´Koronavirus´ radio elements")
            }
        } else {
            XCTFail("Failed to get ´Koronavirus´ questionnaire item")
        }
    }

    func test_12_parseConfiguration_logic() {
        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Koronavirus-Logic1" }) {
            XCTAssertNotNil(questionnaireItem.logic)
            XCTAssertNotNil(questionnaireItem.logic?.and)
            XCTAssertFalse(questionnaireItem.logic?.satisfy(["Koronavirus-jatko"]) ?? true)
        } else {
            XCTFail("Failed to get ´Koronavirus-Logic1´ questionnaire item")
        }

        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Koronavirus-Logic2" }) {
            XCTAssertNotNil(questionnaireItem.logic)
            XCTAssertNotNil(questionnaireItem.logic?.or)
            XCTAssertTrue(questionnaireItem.logic?.satisfy(["Koronavirus-jatko"]) ?? false)
        } else {
            XCTFail("Failed to get ´Koronavirus-Logic2´ questionnaire item")
        }
    }

    func test_13_parseConfiguration_regex() {
        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Start" }), let input = questionnaireItem.elements?.first(where: { $0.element == .input }) {
            XCTAssertNotNil(input.pattern)

            do {
                let regex = try NSRegularExpression(pattern: input.pattern!, options: .caseInsensitive)

                let string1 = "+358-123456789"
                XCTAssertTrue(regex.matches(in: string1, range: NSRange(location: 0, length: string1.count)).count > 0)

                let string2 = "@hassan"
                XCTAssertFalse(regex.matches(in: string2, range: NSRange(location: 0, length: string2.count)).count > 0)
            } catch {
                XCTFail(error.localizedDescription)
            }
        } else {
            XCTFail("Failed to get ´input´ questionnaire item")
        }
    }

    func test_20_initiateConfigurations() {
        let preAudienceQuestionnaire = AudienceQuestionnaire(from: questionnaire_raw, for: "preAudienceQuestionnaire")
        XCTAssertNotNil(preAudienceQuestionnaire)
        XCTAssertGreaterThan(preAudienceQuestionnaire.questionnaireConfiguration?.count ?? 0, 0)

        let postAudienceQuestionnaire = AudienceQuestionnaire(from: questionnaire_raw, for: "postAudienceQuestionnaire")
        XCTAssertNil(postAudienceQuestionnaire.questionnaireConfiguration)
    }
}

extension QuestionnaireTests {
    private func openTestFile() throws -> [String:AnyHashable]? {
        let bundle = Bundle(for: QuestionnaireTests.self)
        if let path = bundle.path(forResource: "questionnaire-mock", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            return jsonResult as? [String:AnyHashable]
        }
        return nil
    }
}