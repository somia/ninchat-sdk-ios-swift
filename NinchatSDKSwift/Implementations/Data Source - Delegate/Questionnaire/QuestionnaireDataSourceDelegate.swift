//
// Copyright (c) 15.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/** Delegate for the questionnaire view. */
protocol QuestionnaireDelegate {
    var isLoadingNewElements: Bool! { get set }
    var shouldShowNavigationCell: Bool { get }

    var onUpdateCellContent: (() -> Void)? { get set }
    var onRemoveCellContent: (() -> Void)? { get set }
}

/** Data source for the questionnaire view. */
protocol QuestionnaireDataSource {
    /** How many pages are available. */
    func numberOfPages() -> Int

    /** How many element pages are available. */
    func numberOfMessages(in page: Int) -> Int

    /** Returns the height for each element at given index. */
    func height(at index: IndexPath) -> CGFloat

    /** Returns the cell with element embedded into it at given index. */
    func cell(at index: IndexPath, view: UITableView) -> UITableViewCell

    var session: NINChatSession! { get }
    var viewModel: NINQuestionnaireViewModel! { get set }
    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession)
}

protocol QuestionnaireDataSourceDelegate: QuestionnaireDataSource, QuestionnaireDelegate {}

extension QuestionnaireDataSourceDelegate {
    var shouldShowNavigationCell: Bool {
        if let configuration = try? self.viewModel.getConfiguration() {
            return configuration.buttons?.hasValidButtons ?? true
        }
        return false
    }

    internal func layoutSubview(_ view: UIView, parent: UIView) {
        if parent.subviews.filter({ $0 is QuestionnaireElement }).count > 0 {
            parent.subviews.filter({ $0 is QuestionnaireElement }).forEach({ $0.removeFromSuperview() })
        }
        parent.addSubview(view)

        view
            .fix(top: (0.0, parent), bottom: (0.0, parent))
            .fix(leading: (0.0, parent), trailing: (0.0, parent))
        view.leading?.priority = .almostRequired
        view.trailing?.priority = .almostRequired
    }
}

// MARK: - Closures

extension QuestionnaireDataSourceDelegate {
    internal func onRequirementsUpdated(_ update: Bool, for cell: QuestionnaireNavigationCell) {
        cell.requirementSatisfactionUpdater?(update)
    }

    internal func onNextButtonTapped() {
        guard let nextPage = self.viewModel.goToNextPage() else { return }
        (nextPage) ? self.onUpdateCellContent?() : self.viewModel.finishQuestionnaire(for: nil, autoApply: false)
    }

    internal func onBackButtonTapped(completion: (() -> Void)?) {
        if self.viewModel.clearAnswersForCurrentPage(), self.viewModel.goToPreviousPage() {
            completion?()
        }
    }
}

// MARK: - Cell Setup

extension QuestionnaireDataSourceDelegate {
    internal func setupSettable(view: inout QuestionnaireSettable, element: QuestionnaireElement) {
        view.presetAnswer = self.viewModel.getAnswersForElement(element)
        self.viewModel.resetAnswer(for: element)
    }

    internal func setupSelectable(view: inout QuestionnaireOptionSelectableElement, element: QuestionnaireElement) {
        view.onElementOptionSelected = { [view] option in
            guard self.viewModel.submitAnswer(key: element, value: option.value) else { return }
            if let page = self.viewModel.redirectTargetPage(for: option.value) {
                self.showTargetPage(view: view, page: page, option: option)
            } else if let key = element.elementConfiguration?.name, !key.isEmpty, let page = self.viewModel.logicTargetPage(key: key, value: option.value) {
                self.showTargetPage(view: view, page: page, option: option)
            }
            /// Load the next element if the selected element was a radio or checkbox without any navigation block (redirect/logic)
            else if view is QuestionnaireElementRadio || view is QuestionnaireElementCheckbox {
                guard !self.viewModel.shouldWaitForNextButton else { return }
                self.onNextButtonTapped()
            }
        }
        view.onElementOptionDeselected = { _ in
            self.viewModel.removeAnswer(key: element)
        }
    }

    internal func setupFocusable(view: inout QuestionnaireFocusableElement) {
        view.onElementFocused = { _ in }
        view.onElementDismissed = {  element in
            if let textView = element as? QuestionnaireElementTextArea, let text = textView.view.text, !text.isEmpty, (textView.isCompleted ?? true) {
                _ = self.viewModel.submitAnswer(key: element, value: textView.view.text)
            } else if let textField = element as? QuestionnaireElementTextField, let text = textField.view.text, !text.isEmpty, (textField.isCompleted ?? true) {
                _ = self.viewModel.submitAnswer(key: element, value: textField.view.text)
            } else {
                self.viewModel.removeAnswer(key: element)
            }
        }
    }

    private func showTargetPage(view: QuestionnaireOptionSelectableElement, page: Int, option: ElementOption) {
        if self.viewModel.canGoToPage(page), !self.viewModel.shouldWaitForNextButton, self.viewModel.goToPage(page) {
            self.onUpdateCellContent?()
        }
    }
}
