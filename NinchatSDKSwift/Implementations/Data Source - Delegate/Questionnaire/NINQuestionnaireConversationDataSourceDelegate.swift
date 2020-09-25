//
// Copyright (c) 15.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireConversationHelpers: QuestionnaireDataSourceDelegate {
    func insertSection() -> Int
    func insertRow() -> Int
    func removeSection() -> Int
}

final class NINQuestionnaireConversationDataSourceDelegate: QuestionnaireDataSourceDelegate {

    fileprivate var sectionCount = 0
    fileprivate var rowCount: [Int] = []
    internal var elements: [[QuestionnaireElement]] = []
    internal var configurations: [QuestionnaireConfiguration] = []
    internal var requirementsSatisfied: Bool = false
    internal var shouldShowNavigationCells: [Bool] = []

    // MARK: - NINQuestionnaireFormDelegate

    private weak var session: NINChatSession?

    var viewModel: NINQuestionnaireViewModel!
    weak var sessionManager: NINChatSessionManager?
    var onUpdateCellContent: (() -> Void)?
    var onRemoveCellContent: (() -> Void)?

    // MARK: - NINQuestionnaireFormDataSource

    var isLoadingNewElements: Bool! = false {
        didSet {
            if isLoadingNewElements { rowCount[sectionCount-1] = 1 }
            else { rowCount[sectionCount-1] = 0 }
        }
    }

    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession, sessionManager: NINChatSessionManager) {
        self.session = session
        self.sessionManager = sessionManager
        self.viewModel = viewModel
    }

    deinit {
        rowCount.removeAll()
        elements.removeAll()
        configurations.removeAll()
        shouldShowNavigationCells.removeAll()
    }

    func numberOfPages() -> Int { sectionCount }

    func numberOfMessages(in page: Int) -> Int { rowCount[page] }

    func height(at index: IndexPath) -> CGFloat {
        do {
            if self.isLoadingNewElements, self.elements.count <= index.section, index.row == 0 { return 75.0 }

            if self.elements.count > index.section {
                if index.row >= self.elements[index.section].count { return self.shouldShowNavigationCells[index.section] ? 55.0 : 0.0 }
                return self.elements[index.section][index.row].elementHeight
            }

            let elements = try self.viewModel.getElements()
            if index.row == elements.count { return self.shouldShowNavigationCell(at: index.section) ? 55.0 : 0.0 }
            return elements[index.row].elementHeight
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func cell(at index: IndexPath, view: UITableView) -> UITableViewCell {
        do {
            if self.isLoadingNewElements, self.elements.count <= index.section, index.row == 0 { return self.loading(view, cellForRowAt: index) }
            if self.elements.count > index.section {
                return (index.row == self.elements[index.section].count) ? self.navigation(view, cellForRowAt: index) : self.questionnaire(view, cellForRowAt: index)
            }
            self.requirementsSatisfied = self.viewModel.requirementsSatisfied
            self.elements.append(contentsOf: [try self.viewModel.getElements()])
            self.configurations.append(try self.viewModel.getConfiguration())
            self.shouldShowNavigationCells.append(self.shouldShowNavigationCell(at: index.section))
            self.enableCurrentRows()

            return (index.row == (try self.viewModel.getElements().count)) ? self.navigation(view, cellForRowAt: index) : self.questionnaire(view, cellForRowAt: index)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

extension NINQuestionnaireConversationDataSourceDelegate: QuestionnaireConversationHelpers {
    func insertSection() -> Int {
        if sectionCount > 0 { self.disablePreviousRows(true) }
        sectionCount += 1
        rowCount.append(0)
        return sectionCount - 1
    }

    func insertRow() -> Int {
        rowCount[sectionCount-1] += 1
        return rowCount[sectionCount-1] - 1
    }

    func removeSection() -> Int {
        defer { self.disablePreviousRows(false) }

        self.clearCurrentAndPreviousRows()
        sectionCount -= 1
        rowCount.remove(at: sectionCount)
        if elements.count > sectionCount { elements.remove(at: sectionCount) }
        if configurations.count > sectionCount { configurations.remove(at: sectionCount) }
        if shouldShowNavigationCells.count > sectionCount { shouldShowNavigationCells.remove(at: sectionCount) }
        return sectionCount
    }

    private func disablePreviousRows(_ disable: Bool) {
        if self.elements.count >= self.sectionCount { self.elements[sectionCount-1].forEach({ $0.isShown = !disable; $0.alpha = disable ? 0.5 : 1.0 }) }
    }

    private func enableCurrentRows() {
        guard self.elements.count >= self.sectionCount, !(self.elements[sectionCount-1].first?.isShown ?? false) else { return }
        self.elements[sectionCount-1].forEach({ $0.isShown = true;  $0.alpha = 1.0 })
    }

    private func clearCurrentAndPreviousRows() {
        if self.elements.count > self.sectionCount - 1 {
            self.elements[sectionCount-1].forEach({
                ($0 as? QuestionnaireOptionSelectableElement)?.deselectAll()
                ($0 as? QuestionnaireFocusableElement)?.clearAll()
            })
        }
        if self.elements.count > self.sectionCount - 2 {
            self.elements[sectionCount-2].forEach({
                ($0 as? QuestionnaireOptionSelectableElement)?.deselectAll()
                ($0 as? QuestionnaireFocusableElement)?.clearAll()
            })
        }
    }
}

// MARK: - Helper
extension NINQuestionnaireConversationDataSourceDelegate {
    private func loading(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatTypingCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.populateLoading(name: self.sessionManager?.siteConfiguration.audienceQuestionnaireUserName ?? "",
                imageAssets: self.session?.internalDelegate?.imageAssetsDictionary ?? [:],
                colorAssets: self.session?.internalDelegate?.colorAssetsDictionary ?? [:])

        return cell
    }

    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.shouldShowNextButton = self.configurations[indexPath.section].buttons?.hasValidNextButton ?? true
        cell.shouldShowBackButton = (self.configurations[indexPath.section].buttons?.hasValidBackButton ?? true) && indexPath.section != 0
        cell.configuration = self.configurations[indexPath.section]
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = (self.elements[indexPath.section].first?.isShown ?? true) && (indexPath.section == self.sectionCount-1)
        cell.overrideAssets(with: self.session?.internalDelegate)
        // Need to check only for the last item if to enable/disable navigation buttons
        cell.setSatisfaction(self.requirementsSatisfied && indexPath.section == sectionCount-1, lastItem: indexPath.section == sectionCount-1)

        cell.onNextButtonTapped = { [weak self] in
            self?.onNextButtonTapped(elements: self?.elements[indexPath.section])
        }
        cell.onBackButtonTapped = { [weak self] in
            self?.onBackButtonTapped(completion: self?.onRemoveCellContent)
        }
        self.viewModel.requirementSatisfactionUpdater = { [weak self] satisfied in
            self?.requirementsSatisfied = satisfied
            self?.onRequirementsUpdated(satisfied, for: cell)
        }

        return cell
    }

    private func questionnaire(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let element = self.elements[indexPath.section][indexPath.row]
        element.isUserInteractionEnabled = (element.isShown ?? true) && (indexPath.section == self.sectionCount-1)
        element.questionnaireStyle = .conversation
        element.overrideAssets(with: self.session?.internalDelegate)

        if var view = element as? QuestionnaireSettable {
            self.setupSettable(view: &view, element: element)
        }
        if var view = element as? QuestionnaireOptionSelectableElement {
            self.setupSelectable(view: &view, element: element)
        }
        if var view = element as? QuestionnaireFocusableElement {
            self.setupFocusable(view: &view)
        }
        cell.style = .conversation
        cell.indexPath = indexPath
        cell.backgroundColor = .clear
        cell.sessionManager = self.sessionManager
        self.layoutSubview(element, parent: cell.content)

        return cell
    }
}

// MARK: - Audience Register Text
extension NINQuestionnaireConversationDataSourceDelegate {
    func addRegisterSection() {
        guard let registerTitle = self.sessionManager?.siteConfiguration.audienceRegisteredText else { return }
        let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) ?? "Close Chat"
        let registerJSON: [String:AnyHashable] = ["element": "radio", "name": "audienceRegisteredText", "label": registerTitle, "buttons": ["back":false,"next":false], "options":[["label":closeTitle, "value":""]], "redirects":[["target":"_register"]]]

        guard let registerConfiguration = AudienceQuestionnaire(from: [registerJSON]).questionnaireConfiguration, registerConfiguration.count > 0, let element = QuestionnaireElementConverter(configurations: registerConfiguration, style: .conversation).elements.first else { return }
        element.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true

        self.elements.append(element)
        self.configurations.append(contentsOf: registerConfiguration)
        self.requirementsSatisfied = false
        self.shouldShowNavigationCells.append(false)
        self.viewModel.insertRegisteredElement(element, configuration: registerConfiguration)
    }

    func addClosedRegisteredSection() {
        guard let registerTitle = self.sessionManager?.siteConfiguration.audienceClosedRegisteredText else { return }
        let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) ?? "Close Chat"
        let registerJSON: [String:AnyHashable] = ["element": "radio", "name": "audienceClosedRegisteredText", "label": registerTitle, "buttons": ["back":false,"next":false], "options":[["label":closeTitle, "value":""]], "redirects":[["target":"_register"]]]

        guard let registerConfiguration = AudienceQuestionnaire(from: [registerJSON]).questionnaireConfiguration, registerConfiguration.count > 0, let element = QuestionnaireElementConverter(configurations: registerConfiguration, style: .conversation).elements.first else { return }
        element.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true

        self.elements.append(element)
        self.configurations.append(contentsOf: registerConfiguration)
        self.requirementsSatisfied = false
        self.shouldShowNavigationCells.append(false)
        self.viewModel.insertRegisteredElement(element, configuration: registerConfiguration)
    }
}
