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
    var visitedPages: [Int] { set get }
    var preventAutoRedirect: Bool { get set }
    var requirementsSatisfied: Bool { get }
    var shouldWaitForNextButton: Bool { get }
    var questionnaireAnswers: NINLowLevelClientProps { get }

    var onErrorOccurred: ((Error) -> Void)? { get set }
    var onQuestionnaireFinished: ((Queue?, _ queueIsClosed: Bool, _ exit: Bool) -> Void)? { get set }
    var onSessionFinished: (() -> Void)? { get set }
    var requirementSatisfactionUpdater: ((Bool, QuestionnaireConfiguration) -> Void)? { get set }

    var registeredElement: QuestionnaireConfiguration? { get }
    var canAddRegisteredSection: Bool { get }
    var canAddClosedRegisteredSection: Bool { get }
    var completedElement: QuestionnaireConfiguration? { get }
    
    init(sessionManager: NINChatSessionManager?, questionnaireType: AudienceQuestionnaireType)
    func isExitElement(_ element: Any?) -> Bool
    func getConfiguration() throws -> QuestionnaireConfiguration
    func getElements() throws -> [QuestionnaireElement]
    func getAnswersForElement(_ element: QuestionnaireElement, presetOnly: Bool) -> AnyHashable?
    func insertRegisteredElement(_ items: [QuestionnaireItems], configuration: [QuestionnaireConfiguration])
    func clearAnswers() -> Bool
    func redirectTargetPage(_ element: QuestionnaireElement, autoApply: Bool, performClosures: Bool) -> Int?
    func logicTargetPage(_ logic: LogicQuestionnaire, autoApply: Bool, performClosures: Bool) -> Int?
    func goToNextPage() -> Bool?
    func canGoToPreviousPage() -> Bool
    func goToPreviousPage()
    func goToPage(logic: LogicQuestionnaire) -> Bool?
    func goToPage(page: Int) -> Bool
    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable, allowUpdate: Bool?) -> Bool
    func removeAnswer(key: QuestionnaireElement?)
    func finishQuestionnaire(for logic: LogicQuestionnaire?, redirect: ElementRedirect?, autoApply: Bool)
    func finishPostQuestionnaire()
}
extension NINQuestionnaireViewModel {
    func redirectTargetPage(_ element: QuestionnaireElement, autoApply: Bool = true, performClosures: Bool = true) -> Int? {
        self.redirectTargetPage(element, autoApply: autoApply, performClosures: performClosures)
    }
    func logicTargetPage(_ logic: LogicQuestionnaire, autoApply: Bool = true, performClosures: Bool = true) -> Int? {
        self.logicTargetPage(logic, autoApply: autoApply, performClosures: performClosures)
    }
    func getAnswersForElement(_ element: QuestionnaireElement) -> AnyHashable? {
        self.getAnswersForElement(element, presetOnly: true)
    }
}

final class NINQuestionnaireViewModelImpl: NINQuestionnaireViewModel {

    private let operationQueue = OperationQueue.main
    private var setupConnectorOperation: BlockOperation!

    private weak var sessionManager: NINChatSessionManager?
    private var configurations: [QuestionnaireConfiguration] = []
    private let questionnaireType: AudienceQuestionnaireType
    internal var connector: QuestionnaireElementConnector!
    private var items: [QuestionnaireItems] = []
    internal var answers: [String:AnyHashable]! = [:]    // Holds answers saved by the user in the runtime
    internal var preAnswers: [String:AnyHashable]! = [:] // Holds answers already given by the server

    // MARK: - NINQuestionnaireViewModel

    var queue: Queue? {
        didSet {
            guard let queue = queue else { return }
            let setupPreConnectorOperation = BlockOperation { [weak self] in
                self?.setupPreConnector(queue: queue)
            }
            setupPreConnectorOperation.addDependency(self.setupConnectorOperation)
            self.operationQueue.addOperations([setupPreConnectorOperation], waitUntilFinished: false)
        }
    }
    var pageNumber: Int = 0
    var visitedPages: [Int] = [0] /// keep track of visited pages for navigation purposes
    var preventAutoRedirect: Bool = false

    // MARK: - Closures
    var onSessionFinished: (() -> Void)?
    var onErrorOccurred: ((Error) -> Void)?
    var onQuestionnaireFinished: ((Queue?, _ queueIsClosed: Bool, _ exit: Bool) -> Void)?
    var requirementSatisfactionUpdater: ((Bool, QuestionnaireConfiguration) -> Void)?

    init(sessionManager: NINChatSessionManager?, questionnaireType: AudienceQuestionnaireType) {
        self.questionnaireType = questionnaireType
        self.sessionManager = sessionManager

        let configurationOperation = BlockOperation { [weak self] in
            guard let configurations = (questionnaireType == .pre) ? sessionManager?.siteConfiguration.preAudienceQuestionnaire : sessionManager?.siteConfiguration.postAudienceQuestionnaire else { return }
            self?.configurations = configurations
        }
        let elementsOperation = BlockOperation { [weak self] in
            guard let configurations = self?.configurations, let siteConfiguration = self?.sessionManager?.siteConfiguration else { return }
            let style = (questionnaireType == .pre) ? siteConfiguration.preAudienceQuestionnaireStyle : siteConfiguration.postAudienceQuestionnaireStyle

            self?.items = QuestionnaireParser(configurations: configurations, style: style).items
        }
        let connectorOperation = BlockOperation { [weak self] in
            guard let configurations = self?.configurations, let siteConfiguration = self?.sessionManager?.siteConfiguration else { return }
            self?.connector = QuestionnaireElementConnectorImpl(configurations: configurations, style: (questionnaireType == .pre) ? siteConfiguration.preAudienceQuestionnaireStyle : siteConfiguration.postAudienceQuestionnaireStyle)
        }
        self.setupConnectorOperation = BlockOperation { [weak self] in
            if questionnaireType == .pre {
                self?.preAnswers = (try? self?.extractGivenPreAnswers()) ?? [:]
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
        self.connector.logicContainsQueueID = { [weak self] logic in
            self?.queue = self?.sessionManager?.queues.first(where: { $0.queueID == logic?.queueId })
        }
        self.connector.onCompleteTargetReached = { [weak self] logic, redirect, autoApply in
            if self?.hasToWaitForUserConfirmation(autoApply) ?? false { return }
            self?.finishQuestionnaire(for: logic, redirect: redirect, autoApply: autoApply)
        }
        self.connector.onRegisterTargetReached = { [weak self, queue] logic, redirect, autoApply in
            guard let `self` = self else { return }
            if self.hasToWaitForUserConfirmation(autoApply) || self.hasToExitQuestionnaire(logic) { return }

            let targetQueue = self.sessionManager?.audienceQueues.first(where: { $0.queueID == logic?.queueId })
            self.registerAudience(queueID: targetQueue?.queueID ?? queue.queueID) { [weak self] error in
                if let error = error {
                    self?.onErrorOccurred?(error)
                } else {
                    self?.onQuestionnaireFinished?(nil, targetQueue?.isClosed ?? queue.isClosed, false)
                }
            }
        }
    }
    
    internal func hasToWaitForUserConfirmation(_ autoApply: Bool) -> Bool {
        if autoApply {
            return !(self.requirementsSatisfied) || self.shouldWaitForNextButton
        }
        return !self.requirementsSatisfied
    }
    
    internal func hasToExitQuestionnaire(_ logic: LogicQuestionnaire?) -> Bool {
        guard logic != nil, let elements = try? self.getElements() else { return false }
        return elements.compactMap({ $0 as? QuestionnaireExitElement }).first?.isExitElement ?? false
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
            let metadata = self.sessionManager?.audienceMetadata ?? NINLowLevelClientProps()
            metadata.set(value: questionnaireAnswers, forKey: "pre_answers")
            
            try self.sessionManager?.registerAudience(queue: queueID, answers: metadata, completion: completion)
        } catch {
            completion(error)
        }
    }

    /// Check if the page has an answer submitted
    /// if so, it must be cleared to let re-selection
    /// as reported in `https://github.com/somia/mobile/issues/321`
    private func clearAnswersAtPage(_ page: Int) -> Bool {
        guard self.items.count > page, page >= 0, !self.answers.isEmpty else { return false }

        self.items[page]
                .elements?
                .filter({ $0.questionnaireConfiguration != nil || $0.elementConfiguration != nil })
                .forEach({ self.removeAnswer(key: $0) })
        return true
    }
}

// MARK: - NINQuestionnaireViewModel

extension NINQuestionnaireViewModelImpl {
    func finishQuestionnaire(for logic: LogicQuestionnaire?, redirect: ElementRedirect?, autoApply: Bool) {
        if self.questionnaireType == .post {
            self.finishPostQuestionnaire()
            return
        }
        
        /// if the pre audience questionnaire needs to be saved
        guard let queue = self.queue,
              let target: (canJoin: Bool, queue: Queue?) = self.canJoinGivenQueue(withID: queue.queueID),
              let targetQueue = target.queue, target.canJoin else {
            self.connector.onRegisterTargetReached?(logic, redirect, autoApply); return
        }

        if self.questionnaireType == .pre {
            self.sessionManager?.preAudienceQuestionnaireMetadata = self.questionnaireAnswers
        } else {
            self.sessionManager?.preAudienceQuestionnaireMetadata = nil
        }
        self.onQuestionnaireFinished?(targetQueue, targetQueue.isClosed, false)
    }
    
    func finishPostQuestionnaire() {
        guard self.questionnaireType == .post else { return }
        /// if the post audience questionnaire needs to be saved
        /// the behaviour supports `https://github.com/somia/mobile/issues/386`
        self.sessionManager?.preAudienceQuestionnaireMetadata = NINLowLevelClientProps.initiate()
        self.submitPostQuestionnaireAnswers(waitForUserConfirmation: false) { [weak self] _ in
            self?.onQuestionnaireFinished?(nil, false, false)
        }
    }

    func isExitElement(_ element: Any?) -> Bool {
        guard let exitElement = element as? QuestionnaireExitElement else { return false }
        return exitElement.isExitElement
    }
    
    internal func submitPostQuestionnaireAnswers(waitForUserConfirmation: Bool, completion: @escaping ((Error?) -> Void)) {
        if waitForUserConfirmation { return }
        do {
            let payload: [String:Any] = ["data": ["post_answers": self.answers ?? [:]], "time": Date().timeIntervalSince1970]
            try self.sessionManager?.send(type: .metadata, payload: payload, completion: completion)
        } catch {
            completion(error)
        }
    }
}

// MARK :- Answers handlers
extension NINQuestionnaireViewModelImpl {
    var questionnaireAnswers: NINLowLevelClientProps {
        /// taken from `https://stackoverflow.com/a/43615143/7264553`
        NINLowLevelClientProps.initiate(metadata: self.answers.filter({ $0.value as? Bool != false }).merging(self.preAnswers) { (current,new) in new })
    }
    
    var requirementsSatisfied: Bool {
        guard self.items.count > self.pageNumber else { return false }
        guard let elements = self.items[self.pageNumber].elements else { return true } /// Return true if the current item is a logic block

        return elements.filter({
            if let required = $0.elementConfiguration?.required {
                return required
            } else if let required = $0.questionnaireConfiguration?.required {
                return required
            }
            return false
        }).filter({ self.getAnswersForElement($0) == nil }).count == 0
    }

    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable, allowUpdate: Bool?) -> Bool {
        guard !self.isExitElement(key) else { return true }

        if let configuration = key?.elementConfiguration, let cfg = key?.questionnaireConfiguration {
            /// The check below intended to avoid executing closures that had been executed before
            /// But, this wouldn't be the case for the last item in the page
            if !(allowUpdate ?? true), let currentValue = self.answers[configuration.name], value == currentValue { return false }

            self.preventAutoRedirect = false
            self.answers[configuration.name] = value
            self.preAnswers.removeValue(forKey: configuration.name) // clear preset answers if there is a matched one
            self.requirementSatisfactionUpdater?(self.requirementsSatisfied, cfg)
            return true
        }
        return false
    }

    func removeAnswer(key: QuestionnaireElement?) {
        if let configuration = key?.elementConfiguration {
            /// To stop redirect-loop when an item is removed
            /// and the previous answers make a valid redirect/logic case
            self.preventAutoRedirect = true

            self.answers.removeValue(forKey: configuration.name)
            self.requirementSatisfactionUpdater?(self.requirementsSatisfied, configuration)
        }
    }

    func clearAnswers() -> Bool {
        if self.visitedPages.count > 0 {
            self.visitedPages.removeLast()
            return clearAnswersAtPage(self.pageNumber)
        }
        return false
    }
}

// MARK :- Configuration and Element handlers
extension NINQuestionnaireViewModelImpl {
    func getConfiguration() throws -> QuestionnaireConfiguration {
        guard self.configurations.count > self.pageNumber else { throw NINQuestionnaireException.invalidPage(self.pageNumber) }
        return self.configurations[self.pageNumber]
    }

    func getElements() throws -> [QuestionnaireElement] {
        guard self.items.count > self.pageNumber else { throw NINQuestionnaireException.invalidPage(self.pageNumber) }
        return self.items[self.pageNumber].elements ?? []
    }

    func getAnswersForElement(_ element: QuestionnaireElement, presetOnly: Bool = false) -> AnyHashable? {
        guard let configuration = element.elementConfiguration else { return nil }
        if let value = self.preAnswers[configuration.name] {
            return value
        } else if !presetOnly, let value = self.answers[configuration.name] {
            return value
        }
        /// Return 'false' answer as default for checkbox
        /// see `https://github.com/somia/mobile/issues/308`
        else if element is QuestionnaireElementCheckbox {
            return false
        }
        return nil
    }

    func insertRegisteredElement(_ items: [QuestionnaireItems], configuration: [QuestionnaireConfiguration]) {
        self.connector.appendElements(items, configurations: configuration)
        self.configurations.append(contentsOf: configuration)
        self.items.append(contentsOf: items)
        
        
        /// if item.element != nil
        ///     - set the page number to the element
        if let elements: Array<QuestionnaireElement> = items.first?.elements {
            self.pageNumber = self.items
                .compactMap({ $0.elements })
                .lastIndex(where: { $0.isEqualToArray(elements) })!
        }
        /// if items.element == nil
        ///     - find it using available function in the view model
        else if let logic = items.first?.logic {
            self.pageNumber = self.logicTargetPage(logic, autoApply: false, performClosures: false)!
        }
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

    func redirectTargetPage(_ element: QuestionnaireElement, autoApply: Bool, performClosures: Bool) -> Int? {
        guard !self.preventAutoRedirect, let configuration = element.questionnaireConfiguration else { return nil }
        return self.connector.findElementAndPageRedirect(for: self.getAnswersForElement(element, presetOnly: false)
                ?? AnyHashable(""), in: configuration, autoApply: autoApply, performClosures: performClosures).1
    }

    func logicTargetPage(_ logic: LogicQuestionnaire, autoApply: Bool, performClosures: Bool) -> Int? {
        self.connector.findElementAndPageLogic(logic: logic, in: self.answers, autoApply: autoApply, performClosures: performClosures).1
    }

    func goToNextPage() -> Bool? {
        guard !self.preventAutoRedirect, self.requirementsSatisfied else { return nil }
        guard self.items.count > self.pageNumber + 1 else { return false }

        if let logic = self.items[self.pageNumber + 1].logic {
           return self.goToPage(logic: logic)
        } else if self.items[self.pageNumber + 1].elements != nil {
            return self.goToPage(page: self.pageNumber + 1)
        }
        return false
    }

    func canGoToPreviousPage() -> Bool {
        (self.visitedPages.count > 0) && (self.visitedPages.last != nil)
    }

    func goToPreviousPage() {
        self.pageNumber = self.visitedPages.last!
    }

    func goToPage(page: Int) -> Bool {
        guard self.requirementsSatisfied, page >= 0 else { return false }

        self.pageNumber = page
        self.visitedPages.append(page)
        return true
    }

    @discardableResult
    func goToPage(logic: LogicQuestionnaire) -> Bool? {
        let target = logicTargetPage(logic, autoApply: false)

        switch target {
        case -2:
            /// This is a _exit logic
            /// Simply exit the questionnaire and do nothing
            self.onQuestionnaireFinished?(nil, false, true)
            return nil
        case -1:
            /// This is a _register or _complete logic
            /// Which is handled by appropriate closures. Skip for now
            return nil
        case nil:
            /// No target is found, move to the next page
            self.pageNumber += 1
            return goToNextPage()
        default:
            /// Move to the target
            return self.goToPage(page: target!)
        }
    }
}

// MARK : - Register Audience Helpers
extension NINQuestionnaireViewModelImpl {
    var registeredElement: QuestionnaireConfiguration? {
        self.connector.findConfiguration(label: "_registered", in: self.configurations)
    }

    var canAddRegisteredSection: Bool {
        guard self.questionnaireType == .pre else {
            return false
        }
        
        /// Check if the questionnaire contains _registered element or logic first
        if self.registeredElement != nil {
            return false
        }

        /// if not, check if there is a text for the audience register
        return self.sessionManager?.siteConfiguration.audienceRegisteredText != nil
    }

    var canAddClosedRegisteredSection: Bool {
        self.sessionManager?.siteConfiguration.audienceRegisteredClosedText != nil
    }
}

// MARK :- Complete Questionnaire Helpers
extension NINQuestionnaireViewModelImpl {
    var completedElement: QuestionnaireConfiguration? {
        self.connector.findConfiguration(label: "_completed", in: self.configurations)
    }
}
