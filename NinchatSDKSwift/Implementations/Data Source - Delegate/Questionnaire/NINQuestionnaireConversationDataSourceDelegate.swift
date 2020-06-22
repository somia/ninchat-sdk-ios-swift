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
    fileprivate var elements: [[QuestionnaireElement]] = []
    fileprivate var configurations: [QuestionnaireConfiguration] = []
    fileprivate var requirementSatisfactions: [Bool] = []

    // MARK: - NINQuestionnaireFormDelegate

    var session: NINChatSession!
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

    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession) {
        self.session = session
        self.viewModel = viewModel
    }

    func numberOfPages() -> Int { sectionCount }

    func numberOfMessages(in page: Int) -> Int { rowCount[page] }

    func height(at index: IndexPath) -> CGFloat {
        do {
            if self.isLoadingNewElements, self.elements.count <= index.section, index.row == 0 { return 75.0 }
            if self.elements.count > index.section {
                if index.row >= self.elements[index.section].count { return 55.0 }
                return self.elements[index.section][index.row].elementHeight
            }

            if index.row == (try self.viewModel.getElements().count) { return 55.0 }
            return try self.viewModel.getElements()[index.row].elementHeight
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

            return (index.row == (try self.viewModel.getElements().count)) ? self.navigation(view, cellForRowAt: index) : self.questionnaire(view, cellForRowAt: index)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

extension NINQuestionnaireConversationDataSourceDelegate: QuestionnaireConversationHelpers {
    func insertSection() -> Int {
        sectionCount += 1
        rowCount.append(0)
        return sectionCount - 1
    }

    func insertRow() -> Int {
        rowCount[sectionCount-1] += 1
        return rowCount[sectionCount-1] - 1
    }

    func removeSection() -> Int {
        rowCount.remove(at: sectionCount-1)
        self.elements.remove(at: sectionCount-1)
        self.requirementSatisfactions.remove(at: sectionCount-1)
        sectionCount -= 1
        return sectionCount
    }
}

// MARK: - Helper
extension NINQuestionnaireConversationDataSourceDelegate {
    private func loading(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatTypingCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.populateLoading(name: self.session.sessionManager.siteConfiguration.audienceQuestionnaireUserName ?? "",
                imageAssets: self.session.sessionManager.delegate?.imageAssetsDictionary ?? [:],
                colorAssets: self.session.sessionManager.delegate?.colorAssetsDictionary ?? [:])

        return cell
    }

    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> QuestionnaireNavigationCell {
        let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.configuration = self.configurations[indexPath.section]
        cell.requirementsSatisfied = self.requirementSatisfactions[indexPath.section]
        cell.overrideAssets(with: self.session)

        self.viewModel.requirementSatisfactionUpdater = { [weak self] satisfied in
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

        return cell
    }

    private func questionnaire(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> QuestionnaireCell {
        let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let element = self.elements[indexPath.section][indexPath.row]
        element.overrideAssets(with: self.session)

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
        cell.sessionManager = self.session.sessionManager
        self.layoutSubview(element, parent: cell.content)

        return cell
    }
}
