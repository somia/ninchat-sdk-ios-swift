//
// Copyright (c) 27.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class QuestionnaireElementConnectorRedirectTests: XCTestCase {
    private var questionnaire_preAudience: AudienceQuestionnaire?
    private lazy var configuration: QuestionnaireConfiguration? = {
        self.questionnaire_preAudience?.questionnaireConfiguration?.first(where: { $0.name == "Aiheet" })
    }()
    private lazy var connector: QuestionnaireElementConnectorImpl = {
        QuestionnaireElementConnectorImpl(configurations: self.questionnaire_preAudience!.questionnaireConfiguration!)
    }()
    private lazy var elementRedirect1: ElementRedirect = {
        ElementRedirect(pattern: "Mikä on koronavirus", target: "Koronavirus")
    }()
    private lazy var elementRedirect2: ElementRedirect = {
        ElementRedirect(pattern: "Huolen tai epävarmuuden sietäminen", target: "Huolet")
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

    func test_10_find_redirect() {
        let target = connector.findAssociatedRedirect(for: "Mikä on koronavirus", in: self.configuration!)
        XCTAssertNotNil(target)
        XCTAssertEqual(target?.target, elementRedirect1.target)
    }

    func test_11_find_redirect() {
        let target = connector.findAssociatedRedirect(for: "Huolen tai epävarmuuden sietäminen", in: self.configuration!)
        XCTAssertNotNil(target)
        XCTAssertEqual(target?.target, elementRedirect2.target)
    }

    func test_12_find_redirect() {
        let target = connector.findAssociatedRedirect(for: "Sovitut", in: self.configuration!)
        XCTAssertNil(target)
    }

    func test_13_find_configuration() {
        let target = connector.findTargetRedirectConfiguration(from: self.elementRedirect1)
        XCTAssertNotNil(target.0)
        XCTAssertNotNil(target.1)
        XCTAssertEqual(target.1, 1)
    }

    func test_14_find_configuration() {
        let target = connector.findTargetRedirectConfiguration(from: self.elementRedirect2)
        XCTAssertNotNil(target.0)
        XCTAssertNotNil(target.1)
        XCTAssertEqual(target.1, 25)
    }

    func test_15_find_element() {
        let targetQuestionnaire = connector.findTargetRedirectConfiguration(from: self.elementRedirect1).0
        let targetView = connector.findTargetElement(for: targetQuestionnaire!)
        XCTAssertNotNil(targetView.0)
        XCTAssertNotNil(targetView.1)
        XCTAssertEqual(targetView.1, 1)
    }

    func test_16_find_element() {
        let targetQuestionnaire = connector.findTargetRedirectConfiguration(from: self.elementRedirect2).0
        let targetView = connector.findTargetElement(for: targetQuestionnaire!)
        XCTAssertNotNil(targetView.0)
        XCTAssertNotNil(targetView.1)
        XCTAssertEqual(targetView.1, 9)
    }

    // Acceptance
    func test_20_acceptance() {
        let targetElement = connector.findElementAndPageRedirect(for: "Mikä on koronavirus", in: self.configuration!)
        XCTAssertNotNil(targetElement.0)
        XCTAssertNotNil(targetElement.1)

        XCTAssertEqual(targetElement.0?.count, 2)
        XCTAssertNotNil(targetElement.0?[0] as? QuestionnaireElementText)
        XCTAssertNotNil(targetElement.0?[1] as? QuestionnaireElementRadio)
        XCTAssertEqual(targetElement.1, 1)
    }
}

extension QuestionnaireElementConnectorRedirectTests {
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
