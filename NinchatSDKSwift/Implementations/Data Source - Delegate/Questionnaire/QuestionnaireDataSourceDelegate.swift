//
// Copyright (c) 15.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/** Delegate for the questionnaire view. */
protocol QuestionnaireDelegate: class {
    var isLoadingNewElements: Bool! { get set }
    var onUpdateCellContent: (() -> Void)? { get set }
    var onRemoveCellContent: (() -> Void)? { get set }

    func shouldShowNavigationCell(at index: Int) -> Bool
}

/** Data source for the questionnaire view. */
protocol QuestionnaireDataSource: class {
    /** How many pages are available. */
    func numberOfPages() -> Int

    /** How many element pages are available. */
    func numberOfMessages(in page: Int) -> Int

    /** Returns the height for each element at given index. */
    func height(at index: IndexPath) -> CGFloat

    /** Returns the cell with element embedded into it at given index. */
    func cell(at index: IndexPath, view: UITableView) -> UITableViewCell

    /** Add an extra section/page to questionnaires to show 'AudienceRegisteredText' */
    var canAddRegisteredSection: Bool { get }
    func addRegisterSection()

    /** Add an extra section/page to questionnaires to show 'audienceRegisteredClosedText' */
    var canAddClosedRegisteredSection: Bool { get }
    func addClosedRegisteredSection()

    var viewModel: NINQuestionnaireViewModel! { get set }
    var sessionManager: NINChatSessionManager? { get set }
    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession, sessionManager: NINChatSessionManager)
}

protocol QuestionnaireDataSourceDelegate: QuestionnaireDataSource, QuestionnaireDelegate {}

extension QuestionnaireDataSourceDelegate {
    var canAddRegisteredSection: Bool {
        self.sessionManager?.siteConfiguration.audienceRegisteredText != nil
    }

    var canAddClosedRegisteredSection: Bool {
        self.sessionManager?.siteConfiguration.audienceClosedRegisteredText != nil
    }

    internal func shouldShowNavigationCell(at index: Int) -> Bool {
        guard let configuration = try? self.viewModel.getConfiguration() else { return false }
        if index == 0 {
            return configuration.buttons?.hasValidNextButton ?? true
        }
        return configuration.buttons?.hasValidButtons ?? true
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

    internal func onNextButtonTapped(elements: [QuestionnaireElement]?) {
        /// The 'redirect' is not available for group elements, So if elements.count > 1, skip search for redirects
        if let elements = elements, elements.count == 1, let page = self.viewModel.redirectTargetPage(elements[0], autoApply: false)  {
            if page >= 0, self.showTargetPage(page: page) { return }
            /// This is a _register or _complete closure
            if page == -1 { return }
        }

        guard let nextPage = self.viewModel.goToNextPage() else { return }
        (nextPage) ? self.onUpdateCellContent?() : self.viewModel.finishQuestionnaire(for: nil, redirect: nil, autoApply: false)
    }

    internal func onBackButtonTapped(completion: (() -> Void)?) {
        if self.viewModel.clearAnswers(), self.viewModel.goToPreviousPage() {
            completion?()
        }
    }
}

// MARK: - Cell Setup
extension QuestionnaireDataSourceDelegate {
    internal func setupDefaultAnswers(element: QuestionnaireElement, option: ElementOption) {
        self.viewModel.submitAnswer(key: element, value: option.value)
    }

    internal func setupSettable(element: QuestionnaireElement & QuestionnaireSettable) {
        let setAnswerState: QuestionnaireSettableState = (self.viewModel.redirectTargetPage(element, performClosures: false) ?? -1 >= 0) ? .set : .nothing

        if let checkbox = element as? QuestionnaireElementCheckbox, checkbox.subElements.count > 0 {
            checkbox.subElements.compactMap({ $0.value as? QuestionnaireElementCheckbox }).forEach({
                element.updateSetAnswers(viewModel.getAnswersForElement($0, presetOnly: false), configuration: $0.elementConfiguration, state: setAnswerState)
            })
        } else {
            element.updateSetAnswers(viewModel.getAnswersForElement(element, presetOnly: false), configuration: element.elementConfiguration, state: setAnswerState)
        }
    }

    internal func setupSelectable(view: inout QuestionnaireOptionSelectableElement) {
        view.onElementOptionSelected = { [view] element, option in
            guard self.viewModel.submitAnswer(key: element, value: option.value) else { return }

            /// Load the next element if the selected element was a radio or checkbox without any navigation block (redirect/logic)
            /// It will perform only if the element is not the exit element provided to close the questionnaire
            if (view is QuestionnaireElementRadio || view is QuestionnaireElementCheckbox) {
                if self.viewModel.isExitElement(view) || !self.viewModel.shouldWaitForNextButton {
                    self.onNextButtonTapped(elements: [element])
                }
            }
        }
        view.onElementOptionDeselected = { element, _ in
            self.viewModel.removeAnswer(key: element)
        }
    }

    internal func setupFocusable(view: inout QuestionnaireFocusableElement) {
        view.onElementFocused = { _ in }
        view.onElementDismissed = { [view] element in
            /// First ensure that the element is completed properly, otherwise remove any submitted answer for it
            if let isCompleted = self.isCompletedBorder(view: view as? QuestionnaireHasBorder), !isCompleted {
                self.viewModel.removeAnswer(key: element)
                self.viewModel.requirementSatisfactionUpdater?(false)
            }

            /// Now that the element is completed properly, save the answer
            else if let textView = element as? QuestionnaireElementTextArea, let text = textView.view.text, !text.isEmpty, (textView.isCompleted ?? true) {
                _ = self.viewModel.submitAnswer(key: element, value: textView.view.text)
            } else if let textField = element as? QuestionnaireElementTextField, let text = textField.view.text, !text.isEmpty, (textField.isCompleted ?? true) {
                _ = self.viewModel.submitAnswer(key: element, value: textField.view.text)
            } else {
                self.viewModel.removeAnswer(key: element)
            }
        }
    }
}

// MARK: - Cell Setup Helpers
extension QuestionnaireDataSourceDelegate {
    private func isCompletedBorder(view: QuestionnaireHasBorder?) -> Bool? {
        guard let view = view else { return nil }
        return view.isCompleted ?? true
    }

    private func showTargetPage(page: Int) -> Bool {
        if self.viewModel.requirementsSatisfied, self.viewModel.goToPage(page) {
            self.onUpdateCellContent?(); return true
        }
        return false
    }
}

// MARK: - Register Audience
extension QuestionnaireDataSourceDelegate {
    internal func registerGroup(title: String, registerTitle: String) -> String {
        let closeTitle = self.sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) ?? "Close Chat"

        /// https://github.com/somia/customer/wiki/Questionnaires#redirect
        /// Singular element can have a redirect property to tell how we continue from that. Redirect cannot be used with a group or element inside group, but you must utilize logics.
        return
            """
            [
                {
                    "name": "Epäilys",
                    "type": "group",
                    "buttons": {
                        "back": false,
                        "next": false
                    },
                    "elements": [
                        {
                            "element": "text",
                            "name": "\(title)",
                            "label": "\(registerTitle)"
                        },
                        {
                            "element": "radio",
                            "name": "\(title)-close",
                            "label": "",
                            "options": [
                                {
                                    "label": "\(closeTitle)",
                                    "value": ""
                                }
                            ]
                        }
                    ]
                },
                {
                    "name": "register-logic",
                    "logic": {
                      "target": "_audienceRegisteredTarget"
                    }
                }
            ]
            """
    }
}
