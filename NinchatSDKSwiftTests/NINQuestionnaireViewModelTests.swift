//
// Copyright (c) 2.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

final class NINQuestionnaireViewModelTests: XCTestCase {
    private lazy var answers: NINLowLevelClientProps = {
        NINLowLevelClientProps.initiate(preQuestionnaireAnswers: ["pre-answer1": "1", "pre-answer2": "2", "Phone":"+358123456789"])
    }()
    private var session: NINChatSessionManagerImpl!
    private var viewModel: NINQuestionnaireViewModelImpl?

    override func setUp() {
        super.setUp()
        let siteConfiguration = SiteConfigurationImpl(configuration: try! openAsset(forResource: "site-configuration-mock"), environments: ["default"])
        self.session = NINChatSessionManagerImpl(session: nil, serverAddress: "", audienceMetadata: self.answers, configuration: nil)
        self.session.setSiteConfiguration(siteConfiguration)

        self.viewModel = NINQuestionnaireViewModelImpl(sessionManager: session, queue: Queue(queueID: "", name: "", isClosed: false), questionnaireType: .pre)
    }

    func test_00_initialization() {
        XCTAssertNotNil(self.session)
        XCTAssertNotNil(self.viewModel)
    }

    func test_10_preAnswersInitiated() {
        XCTAssertNotEqual(self.viewModel?.answers, [:])
        XCTAssertEqual(self.viewModel?.answers["pre-answer1"], "1")
    }

    func test_20_getAnswersForElement() {
        do {
            self.viewModel?.pageNumber = 10
            let elements = try self.viewModel?.getElements()
            XCTAssertEqual(elements?.count ?? 0, 6)

            let startElement = elements?.first(where: { $0.elementConfiguration?.name == "Phone" })
            XCTAssertNotNil(startElement)

            let answer = self.viewModel?.getAnswersForElement(startElement!)
            XCTAssertNotNil(answer)
            XCTAssertEqual(answer as? String, "+358123456789")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_21_setPreAnswers() throws {
        self.viewModel?.pageNumber = 0
        XCTAssertNil(self.viewModel?.tempPageNumber)

        do {
            self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus"]
            let element = try self.viewModel?.getElements()[0]

            self.viewModel?.resetAnswer(for: element!)
            XCTAssertNotNil(self.viewModel?.tempPageNumber)
            XCTAssertEqual(self.viewModel?.tempPageNumber ?? 0, 1)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func test_30_getRequirementsStatus() {
        self.viewModel?.pageNumber = 8
        XCTAssertTrue(self.viewModel?.requirementsSatisfied ?? false)

        self.viewModel?.pageNumber = 0
        XCTAssertFalse(self.viewModel?.requirementsSatisfied ?? true)

        let element = try? self.viewModel?.getElements().first
        self.viewModel?.submitAnswer(key: element!, value: "Mikä on koronavirus")
        XCTAssertTrue(self.viewModel?.requirementsSatisfied ?? false)
    }

    func test_31_getRequirementsStatus() {
        self.viewModel?.pageNumber = 10
        XCTAssertFalse(self.viewModel?.requirementsSatisfied ?? false)

        let textField = try? self.viewModel?.getElements().first(where: { $0 is QuestionnaireElementTextField })
        self.viewModel?.submitAnswer(key: textField!, value: "+358123456789")
        XCTAssertFalse(self.viewModel?.requirementsSatisfied ?? false)

        let textView = try? self.viewModel?.getElements().first(where: { $0 is QuestionnaireElementTextArea })
        self.viewModel?.submitAnswer(key: textView!, value: "This is a sample input")
        XCTAssertTrue(self.viewModel?.requirementsSatisfied ?? false)
    }

    func test_40_pageNavigation() {
        XCTAssertFalse(self.viewModel?.goToPage(8) ?? true)

        let element = try? self.viewModel?.getElements().first
        self.viewModel?.submitAnswer(key: element!, value: "Mikä on koronavirus")
        XCTAssertTrue(self.viewModel?.goToPage(8) ?? false)
    }

    func test_41_waitForNextButton() {
        self.viewModel?.pageNumber = 0
        XCTAssertTrue(self.viewModel?.shouldWaitForNextButton ?? false)

        self.viewModel?.pageNumber = 4
        XCTAssertFalse(self.viewModel?.shouldWaitForNextButton ?? true)
    }

    func test_50_simpleNavigation() {
        self.viewModel?.pageNumber = 10
        XCTAssertFalse(self.viewModel?.canGoToPage(11) ?? true)

        self.viewModel?.answers = ["temp-btn": "Finnish", "temp-btn2": "Finnish"]
        XCTAssertFalse(self.viewModel?.canGoToPage(11) ?? true)

        self.viewModel?.answers = ["temp-btn": "Finnish", "temp-btn2": "Finnish", "comments": "This is unit test"]
        XCTAssertTrue(self.viewModel?.canGoToPage(11) ?? false)
    }

    func test_51_navigationWithRedirects() {
        self.viewModel?.pageNumber = 0
        XCTAssertTrue(self.viewModel?.shouldWaitForNextButton ?? false)

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus"]
        let page = self.viewModel?.redirectTargetPage(for: "Mikä on koronavirus")
        XCTAssertNotNil(page)
        XCTAssertEqual(page ?? 0, 1)

        XCTAssertTrue(self.viewModel?.canGoToPage(page!) ?? false)
        XCTAssertTrue(self.viewModel?.goToPage(page!) ?? false)
    }

    func test_52_navigationWithLogic_Complete() {
        let expect = self.expectation(description: "Expected to reach _complete logic")

        self.viewModel?.connector.onCompleteTargetReached = { logic, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNotNil(logic)
            expect.fulfill()
        }
        self.viewModel?.pageNumber = 11
        self.viewModel?.answers = ["wouldRecommendService": "1"]

        let page = self.viewModel?.logicTargetPage(key: "wouldRecommendService", value: "1")
        XCTAssertNil(page)

        waitForExpectations(timeout: 2.0)
    }

    func test_52_navigationWithLogic_Register() {
        let expect = self.expectation(description: "Expected to reach _register logic")

        self.viewModel?.connector.onRegisterTargetReached = { logic, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNotNil(logic)
            expect.fulfill()
        }
        self.viewModel?.pageNumber = 9
        self.viewModel?.answers = ["Huolet-jatko": "Sulje"]

        let page = self.viewModel?.logicTargetPage(key: "Huolet-jatko", value: "Sulje")
        XCTAssertNil(page)

        waitForExpectations(timeout: 2.0)
    }

    func test_53_navigationAutoApply_Complete() {
        var expectedResult: Bool!
        let expect = self.expectation(description: "Expected to reach _complete logic")
        expect.assertForOverFulfill = false

        self.viewModel?.connector.onCompleteTargetReached = { _, autoApply in
            XCTAssertEqual(self.viewModel!.hasToWaitForUserConfirmation(autoApply), expectedResult)
            expect.fulfill()
        }
        self.viewModel?.pageNumber = 11
        self.viewModel?.answers = ["wouldRecommendService": "1"]

        expectedResult = true
        _ = self.viewModel?.logicTargetPage(key: "wouldRecommendService", value: "1")

        expectedResult = false
        self.viewModel?.finishQuestionnaire(for: nil, autoApply: false)

        waitForExpectations(timeout: 2.0)
    }

    func test_54_navigationAutoApply_Register() {
        var expectedResult: Bool!
        let expect = self.expectation(description: "Expected to reach _register logic")
        expect.assertForOverFulfill = false

        self.viewModel?.connector.onRegisterTargetReached = { _, autoApply in
            XCTAssertEqual(self.viewModel!.hasToWaitForUserConfirmation(autoApply), expectedResult)
            expect.fulfill()
        }
        self.viewModel?.pageNumber = 9
        self.viewModel?.answers = ["Huolet-jatko": "Sulje"]

        expectedResult = true
        _ = self.viewModel?.logicTargetPage(key: "Huolet-jatko", value: "Sulje")

        expectedResult = false
        self.viewModel?.finishQuestionnaire(for: nil, autoApply: false)

        waitForExpectations(timeout: 2.0)
    }

    func test_60_clearAnswers() {
        self.viewModel?.pageNumber = 0
        self.viewModel?.answers = [:]
        XCTAssertFalse(self.viewModel?.clearAnswersForCurrentPage() ?? true)

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus", "arbitraryAnswer": "answer"]
        XCTAssertTrue(self.viewModel?.clearAnswersForCurrentPage() ?? false)
        XCTAssertEqual(self.viewModel?.answers, ["arbitraryAnswer": "answer"])
    }
}
