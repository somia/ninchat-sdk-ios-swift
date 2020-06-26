//
// Copyright (c) 15.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQuestionnaireFormDataSourceDelegate: QuestionnaireDataSourceDelegate {

    // MARK: - NINQuestionnaireFormDelegate

    var session: NINChatSession!
    var viewModel: NINQuestionnaireViewModel!
    var onUpdateCellContent: (() -> Void)?
    var onRemoveCellContent: (() -> Void)?

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
            let elements = try self.viewModel.getElements()
            if index.row == elements.count { return self.shouldShowNavigationCell ? 65.0 : 0.0 }
            return elements[index.row].elementHeight
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
extension NINQuestionnaireFormDataSourceDelegate {
    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> QuestionnaireNavigationCell {
        do {
            let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configuration = try self.viewModel.getConfiguration()
            cell.requirementsSatisfied = self.viewModel.requirementsSatisfied
            cell.overrideAssets(with: self.session)

            self.viewModel.requirementSatisfactionUpdater = { [weak self] satisfied in
                self?.onRequirementsUpdated(satisfied, for: cell)
            }
            cell.onNextButtonTapped = { [weak self] in
                self?.onNextButtonTapped()
            }
            cell.onBackButtonTapped = { [weak self] in
                self?.onBackButtonTapped(completion: self?.onUpdateCellContent)
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
            element.questionnaireStyle = .form
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
            cell.style = .form
            cell.indexPath = indexPath
            cell.backgroundColor = .clear
            cell.sessionManager = self.session.sessionManager
            self.layoutSubview(element, parent: cell.content)

            return cell
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

// MARK: - Audience Register Text
extension NINQuestionnaireFormDataSourceDelegate {
    func addRegisterSection() -> Bool {
        guard let registerTitle = self.session.sessionManager.siteConfiguration.audienceRegisteredText else { return false }
        let closeTitle = self.session.sessionManager.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) ?? "Close Chat"
        let registerJSON: [String:AnyHashable] = ["element": "radio", "name": "audienceRegisteredText", "label": registerTitle, "buttons": ["back":false,"next":false], "options":[["label":closeTitle, "value":""]], "redirects":[["target":"_register"]]]

        guard let registerConfiguration = AudienceQuestionnaire(from: [registerJSON]).questionnaireConfiguration, registerConfiguration.count > 0, let element = QuestionnaireElementConverter(configurations: registerConfiguration).elements.first else { return false }
        element.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true
        self.viewModel.insertRegisteredElement(element, configuration: registerConfiguration)

        return true
    }

    func addClosedRegisteredSection(after interval: Double) -> Bool {
        guard let registerTitle = self.session.sessionManager.siteConfiguration.audienceClosedRegisteredText else { return false }
        let closeTitle = self.session.sessionManager.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) ?? "Close Chat"
        let registerJSON: [String:AnyHashable] = ["element": "radio", "name": "audienceClosedRegisteredText", "label": registerTitle, "buttons": ["back":false,"next":false], "options":[["label":closeTitle, "value":""]], "redirects":[["target":"_register"]]]

        guard let registerConfiguration = AudienceQuestionnaire(from: [registerJSON]).questionnaireConfiguration, registerConfiguration.count > 0, let element = QuestionnaireElementConverter(configurations: registerConfiguration).elements.first else { return false }
        element.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true
        self.viewModel.insertRegisteredElement(element, configuration: registerConfiguration)

        return true
    }
}
