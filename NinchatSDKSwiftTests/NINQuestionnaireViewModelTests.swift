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
            XCTAssertEqual(elements?.count ?? 0, 11)

            let startElement = elements?.first(where: { $0.elementConfiguration?.name == "Phone" })
            XCTAssertNotNil(startElement)

            let answer = self.viewModel?.getAnswersForElement(startElement!)
            XCTAssertNotNil(answer)
            XCTAssertEqual(answer as? String, "+358123456789")
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
}
