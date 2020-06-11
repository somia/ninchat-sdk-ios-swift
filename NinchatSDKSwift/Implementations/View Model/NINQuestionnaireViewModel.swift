//
// Copyright (c) 1.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

protocol NINQuestionnaireViewModel {
    var pageNumber: Int { get set }
    var previousPage: Int { get set }
    var requirementsSatisfied: Bool { get }
    var shouldWaitForNextButton: Bool { get }
    var questionnaireAnswers: NINLowLevelClientProps { get }

    var onErrorOccurred: ((Error) -> Void)? { get set }
    var onQuestionnaireFinished: ((Queue) -> Void)? { get set }
    var onSessionFinished: (() -> Void)? { get set }
    var requirementSatisfactionUpdater: ((Bool) -> Void)? { get set }

    init(sessionManager: NINChatSessionManager, queue: Queue?, questionnaireType: AudienceQuestionnaireType)
    func getConfiguration() throws -> QuestionnaireConfiguration
    func getElements() throws -> [QuestionnaireElement]
    func getAnswersForElement(_ element: QuestionnaireElement) -> AnyHashable?
    func redirectTargetPage(for value: String) -> Int?
    func logicTargetPage(key: String, value: String) -> Int?
    func goToNextPage() -> Bool?
    func goToPreviousPage() -> Bool
    func goToPage(_ page: Int) -> Bool
    func canGoToPage(_ page: Int) -> Bool
    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable)
    func removeAnswer(key: QuestionnaireElement?)
    func finishQuestionnaire(for logic: LogicQuestionnaire?, autoApply: Bool)
}

final class NINQuestionnaireViewModelImpl: NINQuestionnaireViewModel {

    private let sessionManager: NINChatSessionManager
    private let configurations: [QuestionnaireConfiguration]
    internal var connector: QuestionnaireElementConnector!
    private let views: [[QuestionnaireElement]]
    private let queue: Queue?
    internal var answers: [String:AnyHashable]! = [:]

    // MARK: - NINQuestionnaireViewModel

    var pageNumber: Int = 0
    var previousPage: Int = 0
    var tempPageNumber: Int?
    var onSessionFinished: (() -> Void)?
    var onErrorOccurred: ((Error) -> Void)?
    var onQuestionnaireFinished: ((Queue) -> Void)?
    var requirementSatisfactionUpdater: ((Bool) -> Void)?

    init(sessionManager: NINChatSessionManager, queue: Queue?, questionnaireType: AudienceQuestionnaireType) {
        self.queue = queue
        self.sessionManager = sessionManager
        self.configurations = (questionnaireType == .pre) ? sessionManager.siteConfiguration.preAudienceQuestionnaire! : sessionManager.siteConfiguration.postAudienceQuestionnaire!
        self.views = QuestionnaireElementConverter(configurations: configurations).elements
        self.connector = QuestionnaireElementConnectorImpl(configurations: configurations)

        if let queue = queue, questionnaireType == .pre {
            self.answers = (try? self.extractGivenPreAnswers()) ?? [:]
            self.setupPreConnector(queue: queue)
        } else if questionnaireType == .post {
            self.setupPostConnector()
        }
    }

    private func setupPreConnector(queue: Queue) {
        self.connector.logicContainsTags = { [weak self] logic in
            self?.submitTags(logic?.tags ?? [])
        }
        self.connector.onCompleteTargetReached = { [weak self] logic, autoApply in
            if self?.hasToWaitForUserConfirmation(autoApply) ?? false {
                self?.tempPageNumber = (self?.views.count ?? 0) + 1; return
            }
            self?.finishQuestionnaire(for: logic, autoApply: autoApply)
        }
        self.connector.onRegisterTargetReached = { [weak self] logic, autoApply in
            if self?.hasToWaitForUserConfirmation(autoApply) ?? false {
                self?.tempPageNumber = (self?.views.count ?? 0) + 1; return
            }
            self?.registerAudience(queueID: logic?.queue ?? queue.queueID) { error in
                if let error = error {
                    self?.onErrorOccurred?(error)
                } else {
                    self?.onSessionFinished?()
                }
            }
        }
    }

    private func setupPostConnector() {
        self.connector.onRegisterTargetReached = { [weak self] _, autoApply in
            do {
                if self?.hasToWaitForUserConfirmation(autoApply) ?? false {
                    self?.tempPageNumber = (self?.views.count ?? 0) + 1; return
                }
                try self?.sessionManager.send(type: .metadata, payload: ["data": ["post_answers": self?.answers ?? [:]], "time": Date().timeIntervalSince1970]) { error in
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

    private func extractGivenPreAnswers() throws -> [String:AnyHashable] {
        if let answersMetadata: NINResult<NINLowLevelClientProps> = sessionManager.audienceMetadata?.get(forKey: "pre_answers"), case let .success(pre_answers) = answersMetadata {
            let parser = NINChatClientPropsParser()
            try pre_answers.accept(parser)

            return parser.properties.compactMap({ ($0.key, $0.value) as? (String, AnyHashable) }).reduce(into: [:]) { (result: inout [String:AnyHashable], tuple: (key: String, value: AnyHashable)) in
                result[tuple.key] = tuple.value
            }
        }
        return [:]
    }

    private func canJoinGivenQueue(withID id: String) -> (Bool, Queue?) {
        if let targetQueue = self.sessionManager.queues.first(where: { $0.queueID == id }) {
            return (!targetQueue.isClosed, targetQueue)
        }
        return (false, nil)
    }

    private func submitTags(_ tags: [String]) {
        guard !tags.isEmpty else { return }

        self.answers["tags"] = tags.reduce(into: NINLowLevelClientStrings.initiate) { (result: inout NINLowLevelClientStrings, tag: String) in
            result.append(tag)
        }
    }

    private func registerAudience(queueID: String, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.registerQuestionnaire(queue: queueID, answers: NINLowLevelClientProps.initiate(preQuestionnaireAnswers: self.answers), completion: completion)
        } catch {
            completion(error)
        }
    }
}

// MARK: - NINQuestionnaireViewModel

extension NINQuestionnaireViewModelImpl {
    func finishQuestionnaire(for logic: LogicQuestionnaire?, autoApply: Bool) {
        guard let queue = self.queue, let target: (canJoin: Bool, queue: Queue?) = self.canJoinGivenQueue(withID: logic?.queue ?? queue.queueID), let targetQueue = target.queue, target.canJoin else {
            self.connector.onRegisterTargetReached?(logic, autoApply); return
        }

        self.sessionManager.preAudienceQuestionnaireMetadata = self.questionnaireAnswers
        self.onQuestionnaireFinished?(targetQueue)
    }
}

// MARK :- Answers handlers
extension NINQuestionnaireViewModelImpl {
    var questionnaireAnswers: NINLowLevelClientProps {
        NINLowLevelClientProps.initiate(metadata: self.answers)
    }

    var requirementsSatisfied: Bool {
        guard self.views.count > self.pageNumber, !self.answers.isEmpty else { return false }
        return self.views[self.pageNumber].filter({
            if let required = $0.elementConfiguration?.required {
                return required
            } else if let required = $0.questionnaireConfiguration?.required {
                return required
            }
            return false
        }).filter({ self.getAnswersForElement($0) == nil }).count == 0
    }

    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable) {
        if let configuration = key?.elementConfiguration {
            self.answers[configuration.name] = value
        }
        self.requirementSatisfactionUpdater?(self.requirementsSatisfied)
    }

    func removeAnswer(key: QuestionnaireElement?) {
        if let configuration = key?.elementConfiguration {
            self.answers.removeValue(forKey: configuration.name)
        }
        self.requirementSatisfactionUpdater?(self.requirementsSatisfied)
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

    func redirectTargetPage(for value: String) -> Int? {
        do {
            return self.connector.findElementAndPageRedirect(for: value, in: try getConfiguration()).1
        } catch {
            return nil
        }
    }

    func logicTargetPage(key: String, value: String) -> Int? {
        self.connector.findElementAndPageLogic(for: [key:value], in: self.answers).1
    }

    func goToNextPage() -> Bool? {
        guard self.requirementsSatisfied else { return nil }

        /// To navigate to a page saved during element selection
        if let targetPage = tempPageNumber {
            guard self.views.count >= targetPage else { return false }

            self.previousPage = self.pageNumber
            self.pageNumber = targetPage
            self.tempPageNumber = nil
            return true
        }

        if self.views.count > self.pageNumber + 1 {
            self.previousPage = self.pageNumber
            self.pageNumber += 1
            self.tempPageNumber = nil
            return true
        }

        return false
    }

    func goToPreviousPage() -> Bool {
        if self.pageNumber > 0 {
            self.pageNumber = self.previousPage
            return true
        }
        return false
    }

    func goToPage(_ page: Int) -> Bool {
        guard self.requirementsSatisfied else { return false }

        self.previousPage = self.pageNumber
        self.pageNumber = page
        self.tempPageNumber = nil
        return true
    }

    func canGoToPage(_ page: Int) -> Bool {
        tempPageNumber = page
        return self.requirementsSatisfied
    }
}
