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
    internal var requirementSatisfactions: [Bool] = []
    internal var shouldShowNavigationCells: [Bool] = []

    // MARK: - NINQuestionnaireFormDelegate

    private weak var session: NINChatSession?
    private weak var sessionManager: NINChatSessionManager?

    var viewModel: NINQuestionnaireViewModel!
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
        requirementSatisfactions.removeAll()
        shouldShowNavigationCells.removeAll()
    }

    func numberOfPages() -> Int { sectionCount }

    func numberOfMessages(in page: Int) -> Int { rowCount[page] }

    func height(at index: IndexPath) -> CGFloat {
        do {
            if self.isLoadingNewElements, self.elements.count <= index.section, index.row == 0 { return 75.0 }

            if self.elements.count > index.section {
                if index.row >= self.elements[index.section].count { return self.shouldShowNavigationCells[index.section] ? 55.0 : 0.0 }
                if let text = elements[index.section][index.row] as? QuestionnaireElementText {
                    return text.estimateHeight(width: UIScreen.main.bounds.width - 65.0)
                }
                return self.elements[index.section][index.row].elementHeight
            }

            let elements = try self.viewModel.getElements()
            if index.row == elements.count { return self.shouldShowNavigationCell ? 55.0 : 0.0 }
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
            self.elements.append(contentsOf: [try self.viewModel.getElements()])
            self.configurations.append(try self.viewModel.getConfiguration())
            self.requirementSatisfactions.append(self.viewModel.requirementsSatisfied)
            self.shouldShowNavigationCells.append(self.shouldShowNavigationCell)
            self.enableCurrentRows()
            self.clearCurrentRows()

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

        self.clearCurrentRows()
        sectionCount -= 1
        rowCount.remove(at: sectionCount)
        if elements.count > sectionCount { elements.remove(at: sectionCount) }
        if configurations.count > sectionCount { configurations.remove(at: sectionCount) }
        if requirementSatisfactions.count > sectionCount { requirementSatisfactions.remove(at: sectionCount) }
        if shouldShowNavigationCells.count > sectionCount { shouldShowNavigationCells.remove(at: sectionCount) }
        return sectionCount
    }

    private func disablePreviousRows(_ disable: Bool) {
        guard self.elements.count > self.sectionCount else { return }
        self.elements[sectionCount-1].forEach({ $0.isShown = !disable })
    }

    private func enableCurrentRows() {
        guard self.elements.count > self.sectionCount, !(self.elements[sectionCount-1].first?.isShown ?? false) else { return }
        self.elements[sectionCount-1].forEach({ $0.isShown = true })
    }

    private func clearCurrentRows() {
        guard self.elements.count > self.sectionCount else { return }
        self.elements[sectionCount-1].compactMap({ $0 as? QuestionnaireOptionSelectableElement }).forEach({ $0.deselectAll() })
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
        cell.configuration = self.configurations[indexPath.section]
        cell.requirementsSatisfied = self.requirementSatisfactions[indexPath.section]
        cell.overrideAssets(with: self.session?.internalDelegate)

        self.viewModel.requirementSatisfactionUpdater = { [weak self] satisfied in
            guard self?.requirementSatisfactions.count ?? 0 > indexPath.section else { return }

            self?.requirementSatisfactions[indexPath.section] = satisfied
            self?.onRequirementsUpdated(satisfied, for: cell)
        }
        cell.onNextButtonTapped = { [weak self] in
            self?.onNextButtonTapped()
        }
        cell.onBackButtonTapped = { [weak self] in
            self?.onBackButtonTapped(completion: self?.onRemoveCellContent)
        }
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = (self.elements[indexPath.section].first?.isShown ?? true) && (indexPath.section == self.sectionCount-1)

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
    func addRegisterSection() -> Bool {
        guard let registerTitle = self.sessionManager?.siteConfiguration.audienceRegisteredText else { return false }
        let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) ?? "Close Chat"
        let registerJSON: [String:AnyHashable] = ["element": "radio", "name": "audienceRegisteredText", "label": registerTitle, "buttons": ["back":false,"next":false], "options":[["label":closeTitle, "value":""]], "redirects":[["target":"_register"]]]

        guard let registerConfiguration = AudienceQuestionnaire(from: [registerJSON]).questionnaireConfiguration, registerConfiguration.count > 0, let element = QuestionnaireElementConverter(configurations: registerConfiguration).elements.first else { return false }
        element.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true

        self.elements.append(element)
        self.configurations.append(contentsOf: registerConfiguration)
        self.requirementSatisfactions.append(false)
        self.shouldShowNavigationCells.append(false)
        self.viewModel.insertRegisteredElement(element, configuration: registerConfiguration)

        return true
    }

    func addClosedRegisteredSection() -> Bool {
        guard let registerTitle = self.sessionManager?.siteConfiguration.audienceClosedRegisteredText else { return false }
        let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) ?? "Close Chat"
        let registerJSON: [String:AnyHashable] = ["element": "radio", "name": "audienceClosedRegisteredText", "label": registerTitle, "buttons": ["back":false,"next":false], "options":[["label":closeTitle, "value":""]], "redirects":[["target":"_register"]]]

        guard let registerConfiguration = AudienceQuestionnaire(from: [registerJSON]).questionnaireConfiguration, registerConfiguration.count > 0, let element = QuestionnaireElementConverter(configurations: registerConfiguration).elements.first else { return false }
        element.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true

        self.elements.append(element)
        self.configurations.append(contentsOf: registerConfiguration)
        self.requirementSatisfactions.append(false)
        self.shouldShowNavigationCells.append(false)
        self.viewModel.insertRegisteredElement(element, configuration: registerConfiguration)
        return true
    }
}
