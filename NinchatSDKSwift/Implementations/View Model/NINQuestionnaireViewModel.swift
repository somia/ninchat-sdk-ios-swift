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
    var requirementsSatisfied: Bool { get }
    var shouldWaitForNextButton: Bool { get }
    var questionnaireAnswers: NINLowLevelClientProps { get }

    var onErrorOccurred: ((Error) -> Void)? { get set }
    var onQuestionnaireFinished: ((Queue?, _ exit: Bool) -> Void)? { get set }
    var onSessionFinished: (() -> Void)? { get set }
    var requirementSatisfactionUpdater: ((Bool) -> Void)? { get set }

    init(sessionManager: NINChatSessionManager?, audienceMetadata: NINLowLevelClientProps?, questionnaireType: AudienceQuestionnaireType)
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
    func goToPage(_ page: Int) -> Bool
    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable, allowUpdate: Bool?) -> Bool
    func removeAnswer(key: QuestionnaireElement?)
    func finishQuestionnaire(for logic: LogicQuestionnaire?, redirect: ElementRedirect?, autoApply: Bool)
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
    internal var connector: QuestionnaireElementConnector!
    private var items: [QuestionnaireItems] = []
    internal var answers: [String:AnyHashable]! = [:]    // Holds answers saved by the user in the runtime
    internal var preAnswers: [String:AnyHashable]! = [:] // Holds answers already given by the server
    internal var audienceMetadata: NINLowLevelClientProps? // Holds given metadata during the initialization
    private var preventAutoRedirect: Bool = false

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

    // MARK: - Closures
    var onSessionFinished: (() -> Void)?
    var onErrorOccurred: ((Error) -> Void)?
    var onQuestionnaireFinished: ((Queue?, _ exit: Bool) -> Void)?
    var requirementSatisfactionUpdater: ((Bool) -> Void)?

    init(sessionManager: NINChatSessionManager?, audienceMetadata: NINLowLevelClientProps?, questionnaireType: AudienceQuestionnaireType) {
        self.sessionManager = sessionManager
        self.audienceMetadata = audienceMetadata

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
            } else if questionnaireType == .post {
                self?.setupPostConnector()
            }
        }
        let describeQueues = BlockOperation { [weak self] in
            if questionnaireType == .pre, let realm = self?.sessionManager?.realmID {
                self?.describeAllQueues(realm: realm)
            }
        }

        elementsOperation.addDependency(configurationOperation)
        connectorOperation.addDependency(configurationOperation)
        setupConnectorOperation.addDependency(connectorOperation)
        self.operationQueue.addOperations([configurationOperation, elementsOperation, connectorOperation, setupConnectorOperation, describeQueues], waitUntilFinished: false)
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
            if self?.hasToWaitForUserConfirmation(autoApply) ?? false || self?.hasToExitQuestionnaire(logic) ?? false { return }
            self?.registerAudience(queueID: logic?.queueId ?? queue.queueID) { error in
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
                if self?.hasToWaitForUserConfirmation(autoApply) ?? false { return }
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

    internal func describeAllQueues(realm: String) {
        let uniqueQueues = configurations.compactMap({ $0.logic?.queueId }).filter({ [weak self] queueID in
            !(self?.sessionManager?.queues.contains(where: { $0.queueID == queueID }) ?? true)
        })

        try? sessionManager?.describe(realm: realm, queuesID: uniqueQueues) { _ in }
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
            let metadata = self.audienceMetadata ?? NINLowLevelClientProps()
            metadata.set(value: questionnaireAnswers, forKey: "pre_answers")
            
            try self.sessionManager?.registerQuestionnaire(queue: queueID, answers: metadata, completion: completion)
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
        guard let queue = self.queue,
              let target: (canJoin: Bool, queue: Queue?) = self.canJoinGivenQueue(withID: queue.queueID),
              let targetQueue = target.queue, target.canJoin
            else {
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

        if let configuration = key?.elementConfiguration {
            /// The check below intended to avoid executing closures that had been executed before
            /// But, this wouldn't be the case for the last item in the page
            if !(allowUpdate ?? true), let currentValue = self.answers[configuration.name], value == currentValue { return false }

            self.preventAutoRedirect = false
            self.answers[configuration.name] = value
            self.preAnswers.removeValue(forKey: configuration.name) // clear preset answers if there is a matched one
            self.requirementSatisfactionUpdater?(self.requirementsSatisfied)
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
            self.requirementSatisfactionUpdater?(self.requirementsSatisfied)
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
        self.pageNumber = self.items.lastIndex(where: { $0.elements != nil })!
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
        return connector.findElementAndPageRedirect(for: self.getAnswersForElement(element, presetOnly: false)
                ?? AnyHashable(""), in: configuration, autoApply: autoApply, performClosures: performClosures).1
    }

    func logicTargetPage(_ logic: LogicQuestionnaire, autoApply: Bool, performClosures: Bool) -> Int? {
        connector.findElementAndPageLogic(logic: logic, in: self.answers, autoApply: autoApply, performClosures: performClosures).1
    }

    func goToNextPage() -> Bool? {
        guard !self.preventAutoRedirect, self.requirementsSatisfied else { return nil }
        guard self.items.count > self.pageNumber + 1 else { return false }

        if let logic = self.items[self.pageNumber + 1].logic {
            let target = logicTargetPage(logic, autoApply: false)

            switch target {
            case -2:
                /// This is a _exit logic
                /// Simply exit the questionnaire and do nothing
                self.onQuestionnaireFinished?(nil, true)
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
                return self.goToPage(target!)
            }
        } else if self.items[self.pageNumber + 1].elements != nil {
            return self.goToPage(self.pageNumber + 1)
        }
        return false
    }

    func canGoToPreviousPage() -> Bool {
        (self.visitedPages.count > 0) && (self.visitedPages.last != nil)
    }

    func goToPreviousPage() {
        self.pageNumber = self.visitedPages.last!
    }

    func goToPage(_ page: Int) -> Bool {
        guard self.requirementsSatisfied, page >= 0 else { return false }

        self.pageNumber = page
        self.visitedPages.append(page)
        return true
    }
}

