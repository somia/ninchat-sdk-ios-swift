//
// Copyright (c) 15.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireConversationHelpers: QuestionnaireDataSourceDelegate {
    func insertSection() -> Int
    func insertRow() -> Int
}

final class NINQuestionnaireConversationDataSourceDelegate: QuestionnaireDataSourceDelegate {

    fileprivate var sectionCount = 0
    fileprivate var rowCount: [Int] = []
    fileprivate var elements: [[QuestionnaireElement]] = []

    // MARK: - NINQuestionnaireFormDelegate

    var session: NINChatSession!
    var viewModel: NINQuestionnaireViewModel!
    var onUpdateCellContent: (() -> Void)?

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
                if index.row >= self.elements[index.section].count { return 65.0 }
                return self.elements[index.section][index.row].elementHeight
            }

            if index.row == (try self.viewModel.getElements().count) { return 65.0 }
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
        do {
            let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configuration = try self.viewModel.getConfiguration()
            cell.requirementsSatisfied = self.viewModel.requirementsSatisfied
            cell.overrideAssets(with: self.session)

            self.viewModel.requirementSatisfactionUpdater = { satisfied in
                cell.requirementSatisfactionUpdater?(satisfied)
            }
            cell.onNextButtonTapped = { [self] in
                guard let nextPage = self.viewModel.goToNextPage() else { return }
                (nextPage) ? self.onUpdateCellContent?() : self.viewModel.finishQuestionnaire(for: nil, autoApply: false)
            }
            cell.onBackButtonTapped = { [self] in
                _ = self.viewModel.clearAnswersForCurrentPage()
                if self.viewModel.goToPreviousPage() {
                    self.onUpdateCellContent?()
                }
            }
            cell.backgroundColor = .clear

            return cell
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func questionnaire(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> QuestionnaireCell {
        do {
            debugger("** ** indexPath: \(indexPath)")
            let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            let element = self.elements[indexPath.section][indexPath.row]
            element.overrideAssets(with: self.session)

            if var view = element as? QuestionnaireSettable {
                view.presetAnswer = self.viewModel.getAnswersForElement(element)
                self.viewModel.resetAnswer(for: element)
            }
            if var view = element as? QuestionnaireOptionSelectableElement {
                view.onElementOptionSelected = { [self] option in
                    func showTargetPage(_ page: Int) {
                        guard self.viewModel.canGoToPage(page), !self.viewModel.shouldWaitForNextButton else { return }
                        if self.viewModel.goToPage(page) {
                            view.deselect(option: option)
                            self.onUpdateCellContent?()
                        }
                    }

                    self.viewModel.submitAnswer(key: element, value: option.value)
                    if let page = self.viewModel.redirectTargetPage(for: option.value) {
                        showTargetPage(page)
                    } else if let key = element.elementConfiguration?.name, !key.isEmpty, let page = self.viewModel.logicTargetPage(key: key, value: option.value) {
                        showTargetPage(page)
                    }
                }
                view.onElementOptionDeselected = { _ in
                    self.viewModel.removeAnswer(key: element)
                }
            }
            if var view = element as? QuestionnaireFocusableElement {
                view.onElementFocused = { _ in }
                view.onElementDismissed = { [self] element in
                    if let textView = element as? QuestionnaireElementTextArea, let text = textView.view.text, !text.isEmpty, textView.isCompleted {
                        self.viewModel.submitAnswer(key: element, value: textView.view.text)
                    } else if let textField = element as? QuestionnaireElementTextField, let text = textField.view.text, !text.isEmpty, textField.isCompleted {
                        self.viewModel.submitAnswer(key: element, value: textField.view.text)
                    } else {
                        self.viewModel.removeAnswer(key: element)
                    }
                }
            }
            cell.backgroundColor = .clear
            self.layoutSubview(element, parent: cell.content)

            return cell
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
