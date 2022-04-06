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
    internal var shouldShowNavigationCells: [Bool] = []

    // MARK: - NINQuestionnaireFormDelegate

    private weak var delegate: NINChatSessionInternalDelegate?

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

    init(viewModel: NINQuestionnaireViewModel, sessionManager: NINChatSessionManager, delegate: NINChatSessionInternalDelegate?) {
        self.delegate = delegate
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

    func cellHeightComponent(at index: IndexPath) -> (type: AnyClass?, isLoading: Bool, height: CGFloat) {
        do {
            if self.isLoadingNewElements, self.elements.count <= index.section, index.row == 0 {
                return (nil, true, 75.0)
            }

            if self.elements.count > index.section {
                if index.row >= self.elements[index.section].count {
                    return (nil, false, self.shouldShowNavigationCells[index.section] ? 55.0 : 0.0)
                }

                let element = self.elements[index.section][index.row]
                return (element.classForCoder, false, element.elementHeight)
            }

            let elements = try self.viewModel.getElements()
            if index.row == elements.count {
                return (nil, false, self.shouldShowNavigationCell(at: index.section) ? 55.0 : 0.0)
            }

            let element = elements[index.row]
            return (element.classForCoder, false, element.elementHeight)
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

        self.clearCurrentRow()
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

    private func clearCurrentRow() {
        if self.elements.count > self.sectionCount - 1 {
            self.elements[sectionCount-1].forEach({
                ($0 as? QuestionnaireOptionSelectableElement)?.deselectAll()
                ($0 as? QuestionnaireFocusableElement)?.clearAll()
            })
        }
    }
}

// MARK: - Helper
extension NINQuestionnaireConversationDataSourceDelegate {
    private func loading(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QuestionnaireLoadingCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.populateLoading(agentAvatarConfig: AvatarConfig(forQuestionnaire: self.sessionManager),
                imageAssets: self.delegate?.imageAssetsDictionary ?? [:],
                colorAssets: self.delegate?.colorAssetsDictionary ?? [:])

        return cell
    }

    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let configuration = self.configurations[indexPath.section]
        
        cell.isLastItemInTable = indexPath.section == sectionCount-1
        cell.shouldShowNextButton = configuration.buttons?.hasValidNextButton ?? true
        cell.shouldShowBackButton = (configuration.buttons?.hasValidBackButton ?? true) && indexPath.section != 0
        cell.configuration = configuration
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = (self.elements[indexPath.section].first?.isShown ?? true) && (cell.isLastItemInTable)
        cell.overrideAssets(with: self.delegate)
        cell.enableNavigationItems(self.viewModel.requirementsSatisfied, configuration: configuration)
        
        cell.onNextButtonTapped = { [weak self, cell, indexPath, configuration] in
            self?.viewModel.preventAutoRedirect = false
            self?.onNextButtonTapped(elements: self?.elements[indexPath.section])
            cell.enableNavigationItems(false, configuration: configuration)
        }
        cell.onBackButtonTapped = { [weak self] in
            self?.onBackButtonTapped(completion: self?.onRemoveCellContent)
        }
        self.viewModel.requirementSatisfactionUpdater = cell.requirementSatisfactionUpdater

        return cell
    }

    private func questionnaire(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QuestionnaireCellConversation = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let element = self.elements[indexPath.section][indexPath.row]
        element.isUserInteractionEnabled = (element.isShown ?? true) && (indexPath.section == self.sectionCount-1)
        element.questionnaireStyle = .conversation
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
        cell.style = .conversation
        cell.indexPath = indexPath
        cell.backgroundColor = .clear
        cell.sessionManager = self.sessionManager

        cell.addElement(element)
        cell.hideUserNameAndAvatar(indexPath.row != 0)
        layoutSubview(view: (element as? HasTitle)?.titleView, parent: cell.conversationTitleContentView)
        layoutSubview(view: (element as? HasOptions)?.optionsView, parent: cell.conversationOptionsContainerView)
        return cell
    }
}

// MARK: - Audience Register Text
extension NINQuestionnaireConversationDataSourceDelegate {
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

    func addRegisteredLogic() {
        guard let json: Array<[String:AnyHashable]> = registeredLogic().toDictionary() else { return }
        json.forEach({ self.addToQuestionnaire(configuration: $0) })
    }

    private func addToQuestionnaire(configuration: [String:AnyHashable]) {
        guard let configuration = AudienceQuestionnaire(from: [configuration]).questionnaireConfiguration,
              configuration.count > 0
            else { return }

        let items = QuestionnaireParser(configurations: configuration, style: .conversation).items
        items.forEach({ $0.elements?.compactMap({ $0 as? QuestionnaireElementRadio }).first?.isExitElement = true })

        self.elements.append(contentsOf: items.compactMap({ $0.elements }))
        self.configurations.append(contentsOf: configuration)
        self.shouldShowNavigationCells.append(false)
        self.viewModel.insertRegisteredElement(items, configuration: configuration)
    }
}
