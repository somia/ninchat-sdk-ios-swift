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
        XCTAssertNil(self.viewModel?.askedPageNumber)

        do {
            self.viewModel?.preAnswers = ["Aiheet": "Mikä on koronavirus"]
            let element = try self.viewModel?.getElements()[0]

            _ = self.viewModel?.resetAnswer(for: element!)
            XCTAssertNotNil(self.viewModel?.askedPageNumber)
            XCTAssertEqual(self.viewModel?.askedPageNumber ?? 0, 1)
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
        self.viewModel?.pageNumber = 10
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

    func test_52_navigationWithRedirects_Complete() {
        let expect = self.expectation(description: "Expected to reach _complete redirect")

        self.viewModel?.connector.onCompleteTargetReached = { logic, redirect, autoApply in
            XCTAssertTrue(autoApply)
            XCTAssertNil(logic)
            XCTAssertNotNil(redirect)
            expect.fulfill()
        }
        self.viewModel?.pageNumber = 13
        let page = self.viewModel?.redirectTargetPage(for: "")
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
        self.viewModel?.pageNumber = 12
        let page = self.viewModel?.redirectTargetPage(for: "")
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
        self.viewModel?.pageNumber = 11
        self.viewModel?.answers = ["wouldRecommendService": "1"]

        let page = self.viewModel?.logicTargetPage(for: ["wouldRecommendService": "1"])
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
        self.viewModel?.pageNumber = 9
        self.viewModel?.answers = ["Huolet-jatko": "Sulje"]

        let page = self.viewModel?.logicTargetPage(for: ["Huolet-jatko":"Sulje"])
        XCTAssertNotNil(page)
        XCTAssertEqual(page, -1)

        waitForExpectations(timeout: 2.0)
    }

    func test_62_navigationAutoApply_Complete() {
        var expectedResult: Bool!
        let expect = self.expectation(description: "Expected to reach _complete logic")
        expect.assertForOverFulfill = false

        self.viewModel?.connector.onCompleteTargetReached = { _, _, autoApply in
            XCTAssertEqual(self.viewModel!.hasToWaitForUserConfirmation(autoApply), expectedResult)
            expect.fulfill()
        }
        self.viewModel?.pageNumber = 11
        self.viewModel?.answers = ["wouldRecommendService": "1"]

        expectedResult = true
        _ = self.viewModel?.logicTargetPage(for: ["wouldRecommendService":"1"])

        expectedResult = false
        self.viewModel?.finishQuestionnaire(for: nil, redirect: nil, autoApply: false)

        waitForExpectations(timeout: 2.0)
    }

    func test_63_navigationAutoApply_Register() {
        var expectedResult: Bool!
        let expect = self.expectation(description: "Expected to reach _register logic")
        expect.assertForOverFulfill = false

        self.viewModel?.connector.onRegisterTargetReached = { _, _, autoApply in
            XCTAssertEqual(self.viewModel!.hasToWaitForUserConfirmation(autoApply), expectedResult)
            expect.fulfill()
        }
        self.viewModel?.pageNumber = 9
        self.viewModel?.answers = ["Huolet-jatko": "Sulje"]

        expectedResult = true
        _ = self.viewModel?.logicTargetPage(for: ["Huolet-jatko":"Sulje"])

        expectedResult = false
        self.viewModel?.finishQuestionnaire(for: nil, redirect: nil, autoApply: false)

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
        self.viewModel?.pageNumber = 2
        self.viewModel?.visitedPages = [0, 1, 2]

        self.viewModel?.answers = ["Aiheet": "Mikä on koronavirus", "Koronavirus-jatko": "Sulje", "Epäilys-jatko": "Muut aiheet"]
        XCTAssertTrue(self.viewModel?.clearAnswers() ?? false)
        XCTAssertTrue(self.viewModel?.goToPreviousPage() ?? false)
        XCTAssertEqual(self.viewModel?.answers, ["Aiheet": "Mikä on koronavirus"])
        XCTAssertEqual(self.viewModel?.pageNumber, 1)
    }
}
