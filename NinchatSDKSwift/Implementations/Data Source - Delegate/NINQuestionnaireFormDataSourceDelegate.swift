//
// Copyright (c) 15.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQuestionnaireFormDataSourceDelegateImpl: QuestionnaireDataSourceDelegate {

    private let session: NINChatSession!
    private var viewModel: NINQuestionnaireViewModel!

    // MARK: - NINQuestionnaireFormDelegate

    var onUpdateCellContent: (() -> Void)?

    // MARK: - NINQuestionnaireFormDataSource

    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession) {
        self.session = session
        self.viewModel = viewModel
    }

    func numberOfMessages() -> Int {
        do {
            return try self.viewModel.getElements().count + 1
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func height(at index: IndexPath) -> CGFloat {
        do {
            let elements = try self.viewModel.getElements()
            return (index.row == elements.count) ? 65.0 : elements[index.row].elementHeight
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func cell(at index: IndexPath, view: UITableView) -> UITableViewCell {
        do {
            return (index.row == (try self.viewModel.getElements()).count) ? self.navigation(view, cellForRowAt: index) : self.questionnaire(view, cellForRowAt: index)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

// MARK: - Helper
extension NINQuestionnaireFormDataSourceDelegateImpl {
    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> QuestionnaireNavigationCell {
        do {
            let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configuration = try self.viewModel.getConfiguration()
            cell.requirementsSatisfied = self.viewModel.requirementsSatisfied
            cell.overrideAssets(with: self.session)

            self.viewModel.requirementSatisfactionUpdater = { satisfied in
                cell.requirementSatisfactionUpdater?(satisfied)
            }
            cell.onNextButtonTapped = { [weak self] in
                guard let nextPage = self?.viewModel.goToNextPage() else { return }
                (nextPage) ? self?.onUpdateCellContent?() : self?.viewModel.finishQuestionnaire(for: nil, autoApply: false)
            }
            cell.onBackButtonTapped = { [weak self] in
                _ = self?.viewModel.clearAnswersForCurrentPage()
                if self?.viewModel.goToPreviousPage() ?? false {
                    self?.onUpdateCellContent?()
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
            let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            let element = try self.viewModel.getElements()[indexPath.row]
            element.overrideAssets(with: self.session)

            if var view = element as? QuestionnaireSettable {
                view.presetAnswer = self.viewModel.getAnswersForElement(element)
                self.viewModel.resetAnswer(for: element)
            }
            if var view = element as? QuestionnaireOptionSelectableElement {
                view.onElementOptionSelected = { [weak self] option in
                    func showTargetPage(_ page: Int) {
                        guard (self?.viewModel.canGoToPage(page) ?? false), !(self?.viewModel.shouldWaitForNextButton ?? false) else { return }
                        if self?.viewModel.goToPage(page) ?? false {
                            view.deselect(option: option)
                            self?.onUpdateCellContent?()
                        }
                    }

                    self?.viewModel.submitAnswer(key: element, value: option.value)
                    if let page = self?.viewModel.redirectTargetPage(for: option.value) {
                        showTargetPage(page)
                    } else if let page = self?.viewModel.logicTargetPage(key: element.elementConfiguration?.name ?? "", value: option.value) {
                        showTargetPage(page)
                    }
                }
                view.onElementOptionDeselected = { _ in
                    self.viewModel.removeAnswer(key: element)
                }
            }
            if var view = element as? QuestionnaireFocusableElement {
                view.onElementFocused = { _ in }
                view.onElementDismissed = { [weak self] element in
                    if let textView = element as? QuestionnaireElementTextArea, let text = textView.view.text, !text.isEmpty, textView.isCompleted {
                        self?.viewModel.submitAnswer(key: element, value: textView.view.text)
                    } else if let textField = element as? QuestionnaireElementTextField, let text = textField.view.text, !text.isEmpty, textField.isCompleted {
                        self?.viewModel.submitAnswer(key: element, value: textField.view.text)
                    } else {
                        self?.viewModel.removeAnswer(key: element)
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

    private func layoutSubview(_ view: UIView, parent: UIView) {
        if parent.subviews.filter({ $0 is QuestionnaireElement }).count > 0 {
            parent.subviews.filter({ $0 is QuestionnaireElement }).forEach({ $0.removeFromSuperview() })
        }
        parent.addSubview(view)

        view
            .fix(top: (0.0, parent), bottom: (0.0, parent))
            .fix(leading: (0.0, parent), trailing: (0.0, parent))
        view.leading?.priority = .required
        view.trailing?.priority = .required
    }
}
