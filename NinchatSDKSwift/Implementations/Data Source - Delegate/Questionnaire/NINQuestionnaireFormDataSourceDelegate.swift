//
// Copyright (c) 15.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQuestionnaireFormDataSourceDelegate: QuestionnaireDataSourceDelegate {

    // MARK: - NINQuestionnaireFormDelegate

    private weak var delegate: NINChatSessionInternalDelegate?

    var viewModel: NINQuestionnaireViewModel!
    weak var sessionManager: NINChatSessionManager?
    var onUpdateCellContent: (() -> Void)?
    var onRemoveCellContent: (() -> Void)?

    // MARK: - NINQuestionnaireFormDataSource

    var isLoadingNewElements: Bool! = false

    init(viewModel: NINQuestionnaireViewModel, sessionManager: NINChatSessionManager, delegate: NINChatSessionInternalDelegate?) {
        self.delegate = delegate
        self.sessionManager = sessionManager
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

    func cellHeightComponent(at index: IndexPath) -> (type: AnyClass?, isLoading: Bool, height: CGFloat) {
        do {
            let elements = try self.viewModel.getElements()
            if index.row == elements.count {
                return (nil, false, self.shouldShowNavigationCell(at: index.row) ? 65.0 : 0.0)
            }

            let element = elements[index.row]
            return (element.classForCoder, false, element.elementHeight)
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

            let configuration = try self.viewModel.getConfiguration()
            cell.shouldShowNextButton = configuration.buttons?.hasValidNextButton ?? true
            cell.shouldShowBackButton = (configuration.buttons?.hasValidBackButton ?? true) && self.viewModel.pageNumber != 0
            cell.configuration = configuration
            cell.overrideAssets(with: self.delegate)
            cell.setSatisfaction(self.viewModel.requirementsSatisfied)

            cell.onNextButtonTapped = { [weak self] in
                do {
                    self?.onNextButtonTapped(elements: try self?.viewModel.getElements())
                } catch {
                    self?.onNextButtonTapped(elements: nil)
                }
            }
            cell.onBackButtonTapped = { [weak self] in
                self?.onBackButtonTapped(completion: self?.onUpdateCellContent)
            }
            cell.backgroundColor = .clear
            self.viewModel.requirementSatisfactionUpdater = cell.requirementSatisfactionUpdater

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
            element.overrideAssets(with: self.delegate)

            if let elementWithDefaultAnswers = element as? QuestionnaireElementHasDefaultAnswer {
                elementWithDefaultAnswers.defaultAnswer?.forEach { [weak self] element, option in
                    self?.setupDefaultAnswers(element: element, option: option)
                }
            }
            if let settableElement = element as? QuestionnaireSettable & QuestionnaireElement {
                self.setupSettable(element: settableElement)
            }
            if var view = element as? QuestionnaireOptionSelectableElement & QuestionnaireElement {
                self.setupSelectable(view: &view, tableView, at: indexPath)
            }
            if var view = element as? QuestionnaireFocusableElement & QuestionnaireElement {
                self.setupFocusable(view: &view)
            }
            if var view = element as? QuestionnaireElement & HasExternalLink {
                self.setupExternalLink(element: &view)
            }
            cell.style = .form
            cell.indexPath = indexPath
            cell.backgroundColor = .clear
            cell.sessionManager = self.sessionManager
            self.layoutSubview(element, parent: cell.content)

            return cell
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

// MARK: - Audience Register Text
extension NINQuestionnaireFormDataSourceDelegate {
    func addRegisterSection() {
        guard let registerTitle = self.sessionManager?.siteConfiguration.audienceRegisteredText,
              let json: Array<[String:AnyHashable]> = registerGroup(title: "register", registerTitle: registerTitle).toDictionary()
                else { return }
        json.forEach({ self.addToQuestionnaire(configuration: $0) })
    }

    func addClosedRegisteredSection() {
        guard let registerTitle = self.sessionManager?.siteConfiguration.audienceRegisteredClosedText,
              let json: Array<[String:AnyHashable]> = registerGroup(title: "register", registerTitle: registerTitle).toDictionary()
            else { return }
        json.forEach({ self.addToQuestionnaire(configuration: $0) })
    }

    private func addToQuestionnaire(configuration: [String:AnyHashable]) {
        guard let configuration = AudienceQuestionnaire(from: [configuration]).questionnaireConfiguration,
              configuration.count > 0
            else { return }

        let items = QuestionnaireParser(configurations: configuration, style: .conversation).items
        items.forEach({ $0.elements?.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true })
        self.viewModel.insertRegisteredElement(items, configuration: configuration)
    }
}
