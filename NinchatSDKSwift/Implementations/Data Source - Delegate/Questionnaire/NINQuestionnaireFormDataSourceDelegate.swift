//
// Copyright (c) 15.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

struct NINQuestionnaireFormDataSourceDelegate: QuestionnaireDataSourceDelegate {

    // MARK: - NINQuestionnaireFormDelegate

    var session: NINChatSession!
    var viewModel: NINQuestionnaireViewModel!
    var onUpdateCellContent: (() -> Void)?

    // MARK: - NINQuestionnaireFormDataSource

    var isLoadingNewElements: Bool! = false

    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession) {
        self.session = session
        self.viewModel = viewModel
    }

    func numberOfPages() -> Int { 1 }

    func numberOfMessages(in page: Int) -> Int {
        do {
            return try self.viewModel.getElements().count + 1
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func height(at index: IndexPath) -> CGFloat {
        do {
            if isLoadingNewElements { return 75.0 }

            let elements = try self.viewModel.getElements()
            return (index.row == elements.count) ? 65.0 : elements[index.row].elementHeight
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    mutating func cell(at index: IndexPath, view: UITableView) -> UITableViewCell {
        do {
            return (index.row == (try self.viewModel.getElements()).count) ? self.navigation(view, cellForRowAt: index) : self.questionnaire(view, cellForRowAt: index)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

// MARK: - Helper
extension NINQuestionnaireFormDataSourceDelegate {
    private func questionnaire(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> QuestionnaireCell {
        do {
            let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            let element = try self.viewModel.getElements()[indexPath.row]
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
