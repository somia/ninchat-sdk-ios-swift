//
// Copyright (c) 11.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import Foundation
@testable import NinchatSDKSwift

class QuestionnaireTests: XCTestCase {
    var questionnaire_raw: [String: AnyHashable]?
    var questionnaire_preAudience: QuestionnairePreAudience?

    override func setUp() {
        super.setUp()

        do {
            self.questionnaire_raw = try openTestFile()
            self.questionnaire_preAudience = try parseTestFile()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_00_openFile() {
        XCTAssertNotNil(questionnaire_raw)
        XCTAssertTrue(questionnaire_raw?["preAudienceQuestionnaire"] is Array<[String:AnyHashable]>)
    }

    func test_01_parseConfiguration() {
        XCTAssertNotNil(self.questionnaire_preAudience)
        XCTAssertGreaterThan(self.questionnaire_preAudience!.questionnaireConfiguration.count, 0)
    }

    func test_10_parseConfiguration_elements() {
        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration.first(where: { $0.name == "Start" }) {
            XCTAssertNotNil(questionnaireItem.elements)
            XCTAssertGreaterThan(questionnaireItem.elements!.count, 0)

            if let elementRadio = questionnaireItem.elements!.first(where: { $0.name == "language" }) {
                XCTAssertNotNil(elementRadio.options)
                XCTAssertGreaterThan(elementRadio.options!.count, 0)

                XCTAssertNotNil(elementRadio.redirects)
                XCTAssertGreaterThan(elementRadio.redirects!.count, 0)
            } else {
                XCTFail("Failed to get ´radio´ questionnaire elements")
            }

            if let elementInput = questionnaireItem.elements?.first(where: { $0.name == "Phone"} ) {
                XCTAssertEqual(elementInput.element, .input)
                XCTAssertEqual(elementInput.type, .text)
                XCTAssertNotNil(elementInput.pattern)
                XCTAssertFalse(elementInput.required ?? true)
            } else {
                XCTFail("Failed to get ´input´ questionnaire elements")
            }
        } else {
            XCTFail("Failed to get ´start´ questionnaire item")
        }
    }

    func test_11_parseConfiguration_logics() {
        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration.first(where: { $0.name == "Logic-language1" }) {
            XCTAssertNotNil(questionnaireItem.logic)
            XCTAssertNotNil(questionnaireItem.logic?.and)
            XCTAssertFalse(questionnaireItem.logic?.satisfy(["language"]) ?? true)

        } else {
            XCTFail("Failed to get ´Logic-language1´ questionnaire item")
        }

        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration.first(where: { $0.name == "Logic-language2" }) {
            XCTAssertNotNil(questionnaireItem.logic)
            XCTAssertNotNil(questionnaireItem.logic?.or)
            XCTAssertTrue(questionnaireItem.logic?.satisfy(["language"]) ?? false)

        } else {
            XCTFail("Failed to get ´Logic-language2´ questionnaire item")
        }
    }

    func test_12_parseConfiguration_regex() {
        if let questionnaireItem = self.questionnaire_preAudience?.questionnaireConfiguration.first(where: { $0.name == "Start" }), let input = questionnaireItem.elements?.first(where: { $0.element == .input }) {
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
}

extension QuestionnaireTests {
    private func openTestFile() throws -> [String:AnyHashable]? {
        let bundle = Bundle(for: QuestionnaireTests.self)
        if let path = bundle.path(forResource: "questionnaire", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            return jsonResult as? [String:AnyHashable]
        }
        return nil
    }

    private func parseTestFile() throws -> QuestionnairePreAudience {
        let data = try JSONSerialization.data(withJSONObject: questionnaire_raw, options: [])
        return try JSONDecoder().decode(QuestionnairePreAudience.self, from: data)
    }
}