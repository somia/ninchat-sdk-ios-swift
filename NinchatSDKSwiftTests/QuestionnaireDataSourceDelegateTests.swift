//
// Copyright (c) 25.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import XCTest
@testable import NinchatSDKSwift

final class QuestionnaireDataSourceDelegateTests: XCTestCase {
    private lazy var session: NINChatSession! = {
        let session = NINChatSession(configKey: "")
        let siteConfiguration = SiteConfigurationImpl(configuration: try! openAsset(forResource: "site-configuration-mock"), environments: ["default"])
        let sessionManager = NINChatSessionManagerImpl(session: nil, serverAddress: "", audienceMetadata: nil, configuration: nil)
        sessionManager.setSiteConfiguration(siteConfiguration)
        session.sessionManager = sessionManager
        
        return session
    }()
    private lazy var viewModel: NINQuestionnaireViewModel! = {
        let viewModel = NINQuestionnaireViewModelImpl(sessionManager: self.session.sessionManager, questionnaireType: .pre)
        viewModel.queue = Queue(queueID: "", name: "", isClosed: false, permissions: QueuePermissions(upload: false), position: 0)
        
        let expect = self.expectation(description: "Expected to initiate the view model")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 10.0)
        
        return viewModel
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero)
        view.register(QuestionnaireCell.self)
        view.register(QuestionnaireLoadingCell.self)
        view.registerClass(QuestionnaireNavigationCell.self)

        return view
    }()

    override func setUp() {
        super.setUp()
        formQuestionnaireDataSource = NINQuestionnaireFormDataSourceDelegate(viewModel: viewModel, sessionManager: self.session.sessionManager, delegate: self.session)
        conversationQuestionnaireDataSource = NINQuestionnaireConversationDataSourceDelegate(viewModel: viewModel, sessionManager: self.session.sessionManager, delegate: self.session)
    }

    private var formQuestionnaireDataSource: QuestionnaireDataSourceDelegate!
    private var conversationQuestionnaireDataSource: QuestionnaireDataSourceDelegate!
}

// MARK: - 'Form-like' tests
extension QuestionnaireDataSourceDelegateTests {
    func test_101_conformance() {
        XCTAssertNotNil(formQuestionnaireDataSource.viewModel)
    }

    func test_102_navigation() {
        XCTAssertTrue(formQuestionnaireDataSource.shouldShowNavigationCell(at: 0))
    }

    func test_103_initialState() {
        XCTAssertEqual(formQuestionnaireDataSource.numberOfPages(), 1)
        XCTAssertEqual(formQuestionnaireDataSource.numberOfMessages(in: 0), 2)
    }

    func test_104_questionnaireCell() {
        formQuestionnaireDataSource.isLoadingNewElements = true
        XCTAssertGreaterThan(formQuestionnaireDataSource.cellHeightComponent(at: IndexPath(row: 0, section: 0), view: self.tableView), 0)
        XCTAssertTrue(formQuestionnaireDataSource.cell(at: IndexPath(row: 0, section: 0), view: self.tableView) is QuestionnaireCell)
        XCTAssertEqual((formQuestionnaireDataSource.cell(at: IndexPath(row: 0, section: 0), view: self.tableView) as! QuestionnaireCell).style, QuestionnaireStyle.form)
    }

    func test_105_navigationCell() {
        formQuestionnaireDataSource.isLoadingNewElements = true
        XCTAssertEqual(formQuestionnaireDataSource.cellHeightComponent(at: IndexPath(row: 1, section: 0), view: self.tableView), 65.0)
        XCTAssertTrue(formQuestionnaireDataSource.cell(at: IndexPath(row: 1, section: 0), view: self.tableView) is QuestionnaireNavigationCell)
    }

    func test_106_closures() {
        let cell = formQuestionnaireDataSource.cell(at: IndexPath(row: 0, section: 0), view: self.tableView) as! QuestionnaireCell
        XCTAssertTrue(cell.content.subviews.first is QuestionnaireElementRadio)
        let radioElement = cell.content.subviews.first as! QuestionnaireElementRadio
        XCTAssertNotNil(radioElement.onElementOptionSelected)
        XCTAssertNotNil(radioElement.onElementOptionDeselected)

        let navigationCell = formQuestionnaireDataSource.cell(at: IndexPath(row: 1, section: 0), view: self.tableView) as! QuestionnaireNavigationCell
        XCTAssertNotNil(navigationCell.onNextButtonTapped)
        XCTAssertNotNil(navigationCell.onBackButtonTapped)
    }
}

// MARK: - 'Conversation-like' tests
extension QuestionnaireDataSourceDelegateTests {
    func test_001_conformance() {
        XCTAssertTrue(conversationQuestionnaireDataSource is QuestionnaireConversationHelpers)
        XCTAssertNotNil(conversationQuestionnaireDataSource.viewModel)
    }

    func test_002_navigation() {
        XCTAssertTrue(conversationQuestionnaireDataSource.shouldShowNavigationCell(at: 0))
    }

    func test_003_initialState() {
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfPages(), 0)
    }

    func test_004_addSection() {
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 0)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfPages(), 1)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfMessages(in: 0), 0)
    }

    func test_005_addRows() {
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 0)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertRow(), 0)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfPages(), 1)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfMessages(in: 0), 1)

        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertRow(), 1)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfPages(), 1)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfMessages(in: 0), 2)
    }

    func test_006_removeSection() {
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 0)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 1)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 2)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 3)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfPages(), 4)

        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).removeSection(), 3)
        XCTAssertEqual(conversationQuestionnaireDataSource.numberOfPages(), 3)
    }

    func test_007_loadingCell() {
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 0)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertRow(), 0)

        conversationQuestionnaireDataSource.isLoadingNewElements = true
        XCTAssertEqual(conversationQuestionnaireDataSource.cellHeightComponent(at: IndexPath(row: 0, section: 0), view: self.tableView), 75.0)
        XCTAssertTrue(conversationQuestionnaireDataSource.cell(at: IndexPath(row: 0, section: 0), view: self.tableView) is QuestionnaireLoadingCell)
    }

    func test_008_questionnaireCell() {
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 0)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertRow(), 0)

        conversationQuestionnaireDataSource.isLoadingNewElements = false
        XCTAssertGreaterThan(conversationQuestionnaireDataSource.cellHeightComponent(at: IndexPath(row: 0, section: 0), view: self.tableView), 0)
        XCTAssertTrue(conversationQuestionnaireDataSource.cell(at: IndexPath(row: 0, section: 0), view: self.tableView) is QuestionnaireCell)
        XCTAssertEqual((conversationQuestionnaireDataSource.cell(at: IndexPath(row: 0, section: 0), view: self.tableView) as! QuestionnaireCell).style, QuestionnaireStyle.conversation)

        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.count, 1)
        XCTAssertTrue((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.first?.first is QuestionnaireElementRadio)
        XCTAssertTrue((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.first?.first is QuestionnaireSettable)
        XCTAssertTrue((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.first?.first is QuestionnaireOptionSelectableElement)

        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).configurations.count, 1)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).configurations.first?.name, "Aiheet")
        XCTAssertEqual(viewModel.requirementsSatisfied, false)

        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).shouldShowNavigationCells.count, 1)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).shouldShowNavigationCells.first, true)
    }

    func test_009_navigationCell() {
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 0)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertRow(), 0)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertRow(), 1)

        conversationQuestionnaireDataSource.isLoadingNewElements = false
        XCTAssertEqual(conversationQuestionnaireDataSource.cellHeightComponent(at: IndexPath(row: 1, section: 0), view: self.tableView), 55.0)
        XCTAssertTrue(conversationQuestionnaireDataSource.cell(at: IndexPath(row: 1, section: 0), view: self.tableView) is QuestionnaireNavigationCell)
    }

    func test_010_closures() {
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertSection(), 0)
        XCTAssertEqual((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).insertRow(), 0)
        _ = conversationQuestionnaireDataSource.cell(at: IndexPath(row: 0, section: 0), view: self.tableView)
        conversationQuestionnaireDataSource.isLoadingNewElements = false

        let radioElement = (conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.first?.first as! QuestionnaireElementRadio
        XCTAssertNotNil(radioElement.onElementOptionSelected)
        XCTAssertNotNil(radioElement.onElementOptionDeselected)

        let navigationCell = conversationQuestionnaireDataSource.cell(at: IndexPath(row: 1, section: 0), view: self.tableView) as! QuestionnaireNavigationCell
        XCTAssertNotNil(navigationCell.onNextButtonTapped)
        XCTAssertNotNil(navigationCell.onBackButtonTapped)
    }

    func test_011_audienceRegisteredSection() {
        let currentElementsCount = (conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.count
        let currentConfigurationCount = (conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).configurations.count
        XCTAssertTrue(conversationQuestionnaireDataSource.canAddRegisteredSection)
        conversationQuestionnaireDataSource.addRegisterSection()
        let newElementsCount = (conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.count
        let newConfigurationCount = (conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).configurations.count

        XCTAssertEqual(newElementsCount, currentElementsCount+1)
        XCTAssertEqual(newConfigurationCount, currentConfigurationCount+2)
        XCTAssertFalse((conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).shouldShowNavigationCells.last ?? true)
    }

    func test_012_audienceClosedRegisteredSection() {
        let currentElementsCount = (conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.count
        let currentConfigurationCount = (conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).configurations.count
        XCTAssertTrue(conversationQuestionnaireDataSource.canAddClosedRegisteredSection)
        conversationQuestionnaireDataSource.addClosedRegisteredSection()
        let newElementsCount = (self.conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).elements.count
        let newConfigurationCount = (self.conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).configurations.count

        XCTAssertEqual(newElementsCount, currentElementsCount+1)
        XCTAssertEqual(newConfigurationCount, currentConfigurationCount+2)
        XCTAssertFalse((self.conversationQuestionnaireDataSource as! NINQuestionnaireConversationDataSourceDelegate).shouldShowNavigationCells.last ?? true)

    }
}
