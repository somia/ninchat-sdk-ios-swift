//
// Copyright (c) 1.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

protocol NINQuestionnaireViewModel {
    var queue: Queue? { get set }
    var pageNumber: Int { get set }
    var previousPage: Int { get set }
    var askedPageNumber: Int? { get }
    var requirementsSatisfied: Bool { get }
    var shouldWaitForNextButton: Bool { get }
    var questionnaireAnswers: NINLowLevelClientProps { get }

    var onErrorOccurred: ((Error) -> Void)? { get set }
    var onQuestionnaireFinished: ((Queue?, _ exit: Bool) -> Void)? { get set }
    var onSessionFinished: (() -> Void)? { get set }
    var requirementSatisfactionUpdater: ((Bool) -> Void)? { get set }

    init(sessionManager: NINChatSessionManager?, questionnaireType: AudienceQuestionnaireType)
    func isExitElement(_ element: Any?) -> Bool
    func getConfiguration() throws -> QuestionnaireConfiguration
    func getElements() throws -> [QuestionnaireElement]
    func getAnswersForElement(_ element: QuestionnaireElement) -> AnyHashable?
    func resetAnswer(for element: QuestionnaireElement)
    func insertRegisteredElement(_ elements: [QuestionnaireElement], configuration: [QuestionnaireConfiguration])
    func clearAnswersForCurrentPage() -> Bool
    func redirectTargetPage(for value: String, autoApply: Bool, performClosures: Bool) -> Int?
    func logicTargetPage(for dictionary: [String:String], autoApply: Bool, performClosures: Bool) -> Int?
    func goToNextPage() -> Bool?
    func goToPreviousPage() -> Bool
    func goToPage(_ page: Int) -> Bool
    func canGoToPage(_ page: Int) -> Bool
    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable) -> Bool
    func removeAnswer(key: QuestionnaireElement?)
    func finishQuestionnaire(for logic: LogicQuestionnaire?, redirect: ElementRedirect?, autoApply: Bool)
}
extension NINQuestionnaireViewModel {
    func redirectTargetPage(for value: String, autoApply: Bool = true, performClosures: Bool = true) -> Int? {
        self.redirectTargetPage(for: value, autoApply: autoApply, performClosures: performClosures)
    }
    func logicTargetPage(for dictionary: [String:String], autoApply: Bool = true, performClosures: Bool = true) -> Int? {
        self.logicTargetPage(for: dictionary, autoApply: autoApply, performClosures: performClosures)
    }
}

final class NINQuestionnaireViewModelImpl: NINQuestionnaireViewModel {

    private let operationQueue = OperationQueue.main

    private weak var sessionManager: NINChatSessionManager?
    private var configurations: [QuestionnaireConfiguration] = []
    internal var connector: QuestionnaireElementConnector!
    private var views: [[QuestionnaireElement]] = []
    internal var answers: [String:AnyHashable]! = [:]
    private var setPageNumber: Int?
    private var setupConnectorOperation: BlockOperation!
    
    // MARK: - NINQuestionnaireViewModel

    var queue: Queue? {
        didSet {
            guard let queue = queue else { return }
            let setupPareConnectorOperation = BlockOperation { [weak self] in
                self?.setupPreConnector(queue: queue)
            }
            setupPareConnectorOperation.addDependency(self.setupConnectorOperation)
            self.operationQueue.addOperations([setupPareConnectorOperation], waitUntilFinished: false)
        }
    }
    var pageNumber: Int = 0
    var previousPage: Int = 0
    private(set) var askedPageNumber: Int? = nil
    var onSessionFinished: (() -> Void)?
    var onErrorOccurred: ((Error) -> Void)?
    var onQuestionnaireFinished: ((Queue?, _ exit: Bool) -> Void)?
    var requirementSatisfactionUpdater: ((Bool) -> Void)?

    init(sessionManager: NINChatSessionManager?, questionnaireType: AudienceQuestionnaireType) {
        self.sessionManager = sessionManager

        let configurationOperation = BlockOperation { [weak self] in
            guard let configurations = (questionnaireType == .pre) ? sessionManager?.siteConfiguration.preAudienceQuestionnaire : sessionManager?.siteConfiguration.postAudienceQuestionnaire else { return }
            self?.configurations = configurations
        }
        let elementsOperation = BlockOperation { [weak self] in
            guard let configurations = self?.configurations, let siteConfiguration = self?.sessionManager?.siteConfiguration else { return }
            self?.views = QuestionnaireElementConverter(configurations: configurations, style: (questionnaireType == .pre) ? siteConfiguration.preAudienceQuestionnaireStyle : siteConfiguration.postAudienceQuestionnaireStyle).elements
        }
        let connectorOperation = BlockOperation { [weak self] in
            guard let configurations = self?.configurations, let siteConfiguration = self?.sessionManager?.siteConfiguration else { return }
            self?.connector = QuestionnaireElementConnectorImpl(configurations: configurations, style: (questionnaireType == .pre) ? siteConfiguration.preAudienceQuestionnaireStyle : siteConfiguration.postAudienceQuestionnaireStyle)
        }
        self.setupConnectorOperation = BlockOperation { [weak self] in
            if questionnaireType == .pre {
                self?.answers = (try? self?.extractGivenPreAnswers()) ?? [:]
            } else if questionnaireType == .post {
                self?.setupPostConnector()
            }
        }

        elementsOperation.addDependency(configurationOperation)
        connectorOperation.addDependency(configurationOperation)
        setupConnectorOperation.addDependency(connectorOperation)
        self.operationQueue.addOperations([configurationOperation, elementsOperation, connectorOperation, setupConnectorOperation], waitUntilFinished: false)
    }

    private func setupPreConnector(queue: Queue) {
        self.connector.logicContainsTags = { [weak self] logic in
            self?.submitTags(logic?.tags ?? [])
        }
        self.connector.onCompleteTargetReached = { [weak self] logic, redirect, autoApply in
            if self?.hasToWaitForUserConfirmation(autoApply) ?? false {
                self?.askedPageNumber = (self?.views.count ?? 0) + 1; return
            }
            self?.finishQuestionnaire(for: logic, redirect: redirect, autoApply: autoApply)
        }
        self.connector.onRegisterTargetReached = { [weak self] logic, redirect, autoApply in
            if self?.hasToWaitForUserConfirmation(autoApply) ?? false {
                self?.askedPageNumber = (self?.views.count ?? 0) + 1; return
            }
            if self?.hasToExitQuestionnaire(redirect) ?? false {
                self?.onQuestionnaireFinished?(nil, true); return
            }
            self?.registerAudience(queueID: logic?.queue ?? queue.queueID) { error in
                if let error = error {
                    self?.onErrorOccurred?(error)
                } else {
                    self?.onQuestionnaireFinished?(nil, false)
                }
            }
        }
    }

    private func setupPostConnector() {
        self.connector.onRegisterTargetReached = { [weak self] _, _, autoApply in
            do {
                if self?.hasToWaitForUserConfirmation(autoApply) ?? false {
                    self?.askedPageNumber = (self?.views.count ?? 0) + 1; return
                }
                try self?.sessionManager?.send(type: .metadata, payload: ["data": ["post_answers": self?.answers ?? [:]], "time": Date().timeIntervalSince1970]) { error in
                    if let error = error {
                        self?.onErrorOccurred?(error)
                    } else {
                        self?.onSessionFinished?()
                    }
                }
            } catch {
                self?.onErrorOccurred?(error)
            }
        }
    }

    internal func hasToWaitForUserConfirmation(_ autoApply: Bool) -> Bool {
        if autoApply {
            return !(self.requirementsSatisfied) || self.shouldWaitForNextButton
        }
        return !self.requirementsSatisfied
    }
    
    internal func hasToExitQuestionnaire(_ redirect: ElementRedirect?) -> Bool {
        guard redirect != nil, let elements = try? self.getElements(), let exitElement = elements.first as? QuestionnaireExitElement else { return false }
        return exitElement.isExitElement
    }

    private func extractGivenPreAnswers() throws -> [String:AnyHashable] {
        if let answersMetadata: NINResult<NINLowLevelClientProps> = sessionManager?.audienceMetadata?.get(forKey: "pre_answers"), case let .success(pre_answers) = answersMetadata {
            let parser = NINChatClientPropsParser()
            try pre_answers.accept(parser)

            return parser.properties.compactMap({ ($0.key, $0.value) as? (String, AnyHashable) }).reduce(into: [:]) { (result: inout [String:AnyHashable], tuple: (key: String, value: AnyHashable)) in
                result[tuple.key] = tuple.value
            }
        }
        return [:]
    }

    private func canJoinGivenQueue(withID id: String) -> (Bool, Queue?)? {
        if let targetQueue = self.sessionManager?.queues.first(where: { $0.queueID == id }) {
            return (!targetQueue.isClosed, targetQueue)
        }
        return (false, nil)
    }

    private func submitTags(_ tags: [String]) {
        guard !tags.isEmpty else { return }

        self.answers["tags"] = tags.reduce(into: NINLowLevelClientStrings()) { (result: inout NINLowLevelClientStrings, tag: String) in
            result.append(tag)
        }
    }

    private func registerAudience(queueID: String, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager?.registerQuestionnaire(queue: queueID, answers: NINLowLevelClientProps.initiate(preQuestionnaireAnswers: self.answers), completion: completion)
        } catch {
            completion(error)
        }
    }
}

// MARK: - NINQuestionnaireViewModel

extension NINQuestionnaireViewModelImpl {
    func finishQuestionnaire(for logic: LogicQuestionnaire?, redirect: ElementRedirect?, autoApply: Bool) {
        guard let queue = self.queue, let target: (canJoin: Bool, queue: Queue?) = self.canJoinGivenQueue(withID: logic?.queue ?? queue.queueID), let targetQueue = target.queue, target.canJoin else {
            self.connector.onRegisterTargetReached?(logic, redirect, autoApply); return
        }

        self.sessionManager?.preAudienceQuestionnaireMetadata = self.questionnaireAnswers
        self.onQuestionnaireFinished?(targetQueue, false)
    }

    func isExitElement(_ element: Any?) -> Bool {
        guard let exitElement = element as? QuestionnaireExitElement else { return false }
        return exitElement.isExitElement
    }
}

// MARK :- Answers handlers
extension NINQuestionnaireViewModelImpl {
    var questionnaireAnswers: NINLowLevelClientProps {
        NINLowLevelClientProps.initiate(metadata: self.answers)
    }

    var requirementsSatisfied: Bool {
        guard self.views.count > self.pageNumber else { return false }
        return self.views[self.pageNumber].filter({
            if let required = $0.elementConfiguration?.required {
                return required
            } else if let required = $0.questionnaireConfiguration?.required {
                return required
            }
            return false
        }).filter({ self.getAnswersForElement($0) == nil }).count == 0
    }

    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable) -> Bool {
        guard !self.isExitElement(key) else { return true }
        if let configuration = key?.elementConfiguration {
            if let currentValue = self.answers[configuration.name], value == currentValue { return false }

            self.answers[configuration.name] = value
            self.requirementSatisfactionUpdater?(self.requirementsSatisfied)
            return true
        }
        return false
    }

    func removeAnswer(key: QuestionnaireElement?) {
        if let configuration = key?.elementConfiguration {
            self.answers.removeValue(forKey: configuration.name)
            self.requirementSatisfactionUpdater?(self.requirementsSatisfied)
        }
    }

    func clearAnswersForCurrentPage() -> Bool {
        guard self.views.count > self.pageNumber, !self.answers.isEmpty else { return false }
        self.views[self.pageNumber].filter({ $0.questionnaireConfiguration != nil || $0.elementConfiguration != nil }).forEach({ self.removeAnswer(key: $0) })
        return true
    }
}

// MARK :- Configuration and Element handlers
extension NINQuestionnaireViewModelImpl {
    func getConfiguration() throws -> QuestionnaireConfiguration {
        let audienceQuestionnaire = self.configurations.filter({ $0.element != nil || $0.elements != nil })
        guard audienceQuestionnaire.count > self.pageNumber else { throw NINQuestionnaireException.invalidPage(self.pageNumber) }

        return audienceQuestionnaire[self.pageNumber]
    }

    func getElements() throws -> [QuestionnaireElement] {
        guard self.views.count > self.pageNumber else { throw NINQuestionnaireException.invalidPage(self.pageNumber) }
        return self.views[self.pageNumber]
    }

    func getAnswersForElement(_ element: QuestionnaireElement) -> AnyHashable? {
        if let configuration = element.elementConfiguration, let value = self.answers[configuration.name] {
            return value
        }
        return nil
    }

    func resetAnswer(for element: QuestionnaireElement) {
        guard let value = self.getAnswersForElement(element) as? String, self.requirementsSatisfied, element.isUserInteractionEnabled else { return }

        if let page = self.redirectTargetPage(for: value, performClosures: false), page >= 0 {
            self.askedPageNumber = page
        } else if let page = self.logicTargetPage(for: [element.elementConfiguration?.name ?? "": value], performClosures: false), page >= 0 {
            self.askedPageNumber = page
        }
    }

    func insertRegisteredElement(_ elements: [QuestionnaireElement], configuration: [QuestionnaireConfiguration]) {
        self.connector.appendElement(elements: elements, configurations: configuration)
        self.configurations.append(contentsOf: configuration)
        self.views.append(elements)
        self.pageNumber = self.views.count-1
    }
}

// MARK :- Navigation
extension NINQuestionnaireViewModelImpl {
    var shouldWaitForNextButton: Bool {
        do {
            return (try self.getConfiguration().buttons)?.hasValidNextButton ?? true
        } catch {
            return false
        }
    }

    func redirectTargetPage(for value: String, autoApply: Bool, performClosures: Bool) -> Int? {
        do {
            return self.connector.findElementAndPageRedirect(for: value, in: try getConfiguration(), autoApply: autoApply, performClosures: performClosures).1
        } catch {
            return nil
        }
    }

    func logicTargetPage(for dictionary: [String:String], autoApply: Bool, performClosures: Bool) -> Int? {
        self.connector.findElementAndPageLogic(for: dictionary, in: self.answers, autoApply: autoApply, performClosures: performClosures).1
    }

    func goToNextPage() -> Bool? {
        guard self.requirementsSatisfied else { return nil }

        /// To navigate to a page saved during element selection
        if let targetPage = askedPageNumber {
            guard self.views.count >= targetPage else { return false }
            return self.goToPage(targetPage)
        }

        if self.views.count > self.pageNumber + 1 {
            return self.goToPage(self.pageNumber+1)
        }

        return false
    }

    func goToPreviousPage() -> Bool {
        if self.pageNumber >= 0, self.pageNumber != self.previousPage {
            self.pageNumber = self.previousPage
            return true
        }
        return false
    }

    func goToPage(_ page: Int) -> Bool {
        guard self.requirementsSatisfied else { return false }

        self.previousPage = self.pageNumber
        self.pageNumber = page
        self.askedPageNumber = nil
        return true
    }

    func canGoToPage(_ page: Int) -> Bool {
        askedPageNumber = page
        return self.requirementsSatisfied
    }
}
