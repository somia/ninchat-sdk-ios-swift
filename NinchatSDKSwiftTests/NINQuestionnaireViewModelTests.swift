//
// Copyright (c) 2.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

final class NINQuestionnaireViewModelTests: XCTestCase {
    private lazy var questionnaire_preAudience: AudienceQuestionnaire = {
        AudienceQuestionnaire(from: try! openAsset(forResource: "questionnaire-mock"), for: "preAudienceQuestionnaire")
    }()
    private lazy var answers: NINLowLevelClientProps = {
        NINLowLevelClientProps.initiate(preQuestionnaireAnswers: ["pre-answer1": "1", "pre-answer2": "2", "Phone":"+358123456789"])
    }()
    private lazy var session: NINChatSessionManagerImpl! = {
        let siteConfiguration = SiteConfigurationImpl(configuration: try! openAsset(forResource: "site-configuration-mock"), environments: ["default"])
        let sessionManager = NINChatSessionManagerImpl(session: nil, serverAddress: "", audienceMetadata: self.answers, configuration: nil)
        sessionManager.setSiteConfiguration(siteConfiguration)
        
        return sessionManager
    }()
    private lazy var viewModel: NINQuestionnaireViewModelImpl? = {
        let viewModel = NINQuestionnaireViewModelImpl(sessionManager: session, audienceMetadata: nil, questionnaireType: .pre)
        viewModel.queue = Queue(queueID: "", name: "", isClosed: false, permissions: QueuePermissions(upload: false))
        
        let expect = self.expectation(description: "Expected to initiate the view model")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 10.0)
        
        return viewModel
    }()
    private lazy var connector: QuestionnaireElementConnectorImpl = {
        QuestionnaireElementConnectorImpl(configurations: self.questionnaire_preAudience.questionnaireConfiguration!, style: .conversation)
    }()

    override func setUp() {
        super.setUp()
    }

    func test_00_initialization() {
        XCTAssertNotNil(self.session)
        XCTAssertNotNil(self.viewModel)
    }

    func test_10_preAnswersInitiated() {
        XCTAssertEqual(self.viewModel?.answers, [:])
        XCTAssertNotEqual(self.viewModel?.preAnswers, [:])
        XCTAssertEqual(self.viewModel?.preAnswers["pre-answer1"], "1")
    }

    func test_20_getAnswersForElement() {
        do {
            self.viewModel?.pageNumber = 28
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

    func test_21_setPreAnswers() {
        self.viewModel?.pageNumber = 0

        do {
            self.viewModel?.preAnswers = ["Aiheet": "Mikä on koronavirus"]
            let element = try self.viewModel?.getElements()[0]
            XCTAssertNotNil(element)
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
        _ = self.viewModel?.submitAnswer(key: element!, value: "Mikä on koronavirus")
        XCTAssertTrue(self.viewModel?.requirementsSatisfied ?? false)
    }

    func test_31_getRequirementsStatus() {
        self.viewModel?.pageNumber = 28
        XCTAssertFalse(self.viewModel?.requirementsSatisfied ?? false)

        let textField = try? self.viewModel?.getElements().first(where: { $0 is QuestionnaireElementTextField })
        _ = self.viewModel?.submitAnswer(key: textField!, value: "+358123456789")
        XCTAssertFalse(self.viewModel?.requirementsSatisfied ?? false)

        let textView = try? self.viewModel?.getElements().first(where: { $0 is QuestionnaireElementTextArea })
        _ = self.viewModel?.submitAnswer(key: textView!, value: "This is a sample input")
        XCTAssertTrue(self.viewModel?.requirementsSatisfied ?? false)
    }

    func test_40_pageNavigation() {
        XCTAssertFalse(self.viewModel?.goToPage(8) ?? true)

        let element = try? self.viewModel?.getElements().first
        _ = self.viewModel?.submitAnswer(key: element!, value: "Mikä on koronavirus")
        XCTAssertTrue(self.viewModel?.goToPage(8) ?? false)
    }

    func test_41_waitForNextButton() {
        self.viewModel?.pageNumber = 0
        XCTAssertTrue(self.viewModel?.shouldWaitForNextButton ?? false)

        self.viewModel?.pageNumber = 13
        XCTAssertFalse(self.viewModel?.shouldWaitForNextButton ?? true)
    }

    func test_50_simpleNavigation() {
        self.viewModel?.pageNumber = 28
        XCTAssertFalse(self.viewModel?.goToPage(30) ?? true)

        self.viewModel?.answers = ["temp-btn": "Finnish", "temp-btn2": "Finnish"]
        XCTAssertFalse(self.viewModel?.goToPage(30) ?? true)

        self.viewModel?.answers = ["temp-btn": "Finnish", "temp-btn2": "Finnish", "comments": "This is unit test"]
        XCTAssertTrue(self.viewModel?.goToPage(30) ?? false)
    }

    func test_51_navigationWithRedirects() {
        self.viewModel?.pageNumber = 0
        XCTAssertTrue(self.viewModel?.shouldWaitForNextButton ?? false)

        let element = self.connector.items.compactMap({ $0.elements }).first(where: { $0.first(where: { $0.questionnaireConfiguration?.name == "Aiheet" }) != nil })?.first
        XCTAssertNotNil(element)

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus"]
        let page = self.viewModel?.redirectTargetPage(element!)
        XCTAssertNotNil(page)
        XCTAssertEqual(page ?? 0, 1)
        XCTAssertTrue(self.viewModel?.goToPage(page!) ?? false)
    }

    func test_52_navigationWithRedirects_Complete() {
        let expect = self.expectation(description: "Expected to reach _complete redirect")

        self.viewModel?.connector.onCompleteTargetReached = { logic, redirect, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNil(logic)
            XCTAssertNotNil(redirect)
            expect.fulfill()
        }

        let element = self.connector.items.compactMap({ $0.elements }).first(where: { $0.first(where: { $0.questionnaireConfiguration?.name == "audienceCompletedText" }) != nil })?.first
        XCTAssertNotNil(element)

        let page = self.viewModel?.redirectTargetPage(element!)
        XCTAssertNotNil(page)
        XCTAssertEqual(page, -1)

        waitForExpectations(timeout: 2.0)
    }
    
    func test_53_navigationWithRedirects_Register() {
        let expect = self.expectation(description: "Expected to reach _register redirect")

        self.viewModel?.connector.onRegisterTargetReached = { logic, redirect, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNil(logic)
            XCTAssertNotNil(redirect)
            expect.fulfill()
        }

        let element = self.connector.items.compactMap({ $0.elements }).first(where: { $0.first(where: { $0.questionnaireConfiguration?.name == "audienceRegisteredText" }) != nil })?.first
        XCTAssertNotNil(element)

        let page = self.viewModel?.redirectTargetPage(element!)
        XCTAssertNotNil(page)
        XCTAssertEqual(page, -1)

        waitForExpectations(timeout: 2.0)
    }

    func test_60_navigationWithLogic_Complete() {
        let expect = self.expectation(description: "Expected to reach _complete logic")

        self.viewModel?.connector.onCompleteTargetReached = { logic, redirect, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNotNil(logic)
            XCTAssertNil(redirect)
            expect.fulfill()
        }
        self.viewModel?.answers = ["wouldRecommendService": "2"]

        let logic = self.connector.configurations.first(where: { $0.name == "recommend-logic" })?.logic
        XCTAssertNotNil(logic)

        let page = self.viewModel?.logicTargetPage(logic!, autoApply: true)
        XCTAssertNotNil(page)
        XCTAssertEqual(page, -1)

        waitForExpectations(timeout: 2.0)
    }

    func test_61_navigationWithLogic_Register() {
        let expect = self.expectation(description: "Expected to reach _register logic")

        self.viewModel?.connector.onRegisterTargetReached = { logic, redirect, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNotNil(logic)
            XCTAssertNil(redirect)
            expect.fulfill()
        }
        self.viewModel?.answers = ["Tartuntatautipäiväraha-jatko": "Sulje"]

        let logic = self.connector.configurations.first(where: { $0.name == "Tartuntatautipäiväraha-Logic1" })?.logic
        XCTAssertNotNil(logic)

        let page = self.viewModel?.logicTargetPage(logic!)
        XCTAssertNotNil(page)
        XCTAssertEqual(page, -1)

        waitForExpectations(timeout: 2.0)
    }

    func test_62_navigationAutoApply_Complete() {
        let logic = self.connector.configurations.first(where: { $0.name == "recommend-logic" })?.logic
        let expect = self.expectation(description: "Expected to reach _complete logic")

        self.viewModel?.connector.onCompleteTargetReached = { _, _, autoApply in
            XCTAssertTrue(self.viewModel!.hasToWaitForUserConfirmation(autoApply))
            expect.fulfill()

        }

        self.viewModel?.answers = ["wouldRecommendService": "2"]
        _ = self.viewModel?.logicTargetPage(logic!)
        waitForExpectations(timeout: 2.0)
    }

    func test_63_navigationAutoApply_Register() {
        let element = self.connector.configurations.first(where: { $0.name == "Tartuntatautipäiväraha-Logic1" })?.logic
        let expect = self.expectation(description: "Expected to reach _register logic")

        self.viewModel?.connector.onRegisterTargetReached = { _, _, autoApply in
            XCTAssertTrue(self.viewModel!.hasToWaitForUserConfirmation(autoApply))
            expect.fulfill()
        }
        self.viewModel?.answers = ["Tartuntatautipäiväraha-jatko": "Sulje"]
        _ = self.viewModel?.logicTargetPage(element!, autoApply: true)

        waitForExpectations(timeout: 2.0)
    }

    func test_70_clearAnswers() {
        self.viewModel?.answers = [:]
        self.viewModel?.pageNumber = 0
        self.viewModel?.visitedPages = [0]

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus"]
        XCTAssertTrue(self.viewModel?.clearAnswers() ?? false)
        XCTAssertFalse(self.viewModel?.goToPreviousPage() ?? true)
        XCTAssertEqual(self.viewModel?.answers, [:])
        XCTAssertEqual(self.viewModel?.pageNumber, 0)
    }

    func test_71_clearAnswers() {
        self.viewModel?.answers = [:]
        self.viewModel?.pageNumber = 1
        self.viewModel?.visitedPages = [0, 1]

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus", "Koronavirus-jatko": "Sulje"]
        XCTAssertTrue(self.viewModel?.clearAnswers() ?? false)
        XCTAssertTrue(self.viewModel?.goToPreviousPage() ?? false)
        XCTAssertEqual(self.viewModel?.answers, [:])
        XCTAssertEqual(self.viewModel?.pageNumber, 0)
    }

    func test_72_clearAnswers() {
        self.viewModel?.answers = [:]
        self.viewModel?.pageNumber = 1
        self.viewModel?.visitedPages = [0, 1]

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus", "Koronavirus-jatko": "Sulje"]
        XCTAssertTrue(self.viewModel?.clearAnswers() ?? false)
        XCTAssertTrue(self.viewModel?.goToPreviousPage() ?? false)
        XCTAssertEqual(self.viewModel?.answers, [:])
        XCTAssertEqual(self.viewModel?.pageNumber, 0)
    }

    func test_73_clearAnswers() {
        self.viewModel?.answers = [:]
        self.viewModel?.pageNumber = 4
        self.viewModel?.visitedPages = [0, 1, 4]

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus", "Koronavirus-jatko": "Sulje", "Epäilys-jatko": "Muut aiheet"]
        XCTAssertTrue(self.viewModel?.clearAnswers() ?? false)
        XCTAssertTrue(self.viewModel?.goToPreviousPage() ?? false)
        XCTAssertEqual(self.viewModel?.answers, ["Aiheet": "Mikä on koronavirus"])
        XCTAssertEqual(self.viewModel?.pageNumber, 1)
    }
}
