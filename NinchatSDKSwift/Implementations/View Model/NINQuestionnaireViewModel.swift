//
// Copyright (c) 1.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import AnyCodable
import NinchatLowLevelClient

protocol NINQuestionnaireViewModel {
    var pageNumber: Int { get set }
    var previousPage: Int { get set }
    var questionnaireAnswers: NINLowLevelClientProps { get }

    var onErrorOccurred: ((Error) -> Void)? { get set }
    var onQuestionnaireFinished: ((Queue) -> Void)? { get set }
    var onSessionFinished: (() -> Void)? { get set }

    init(sessionManager: NINChatSessionManager, queue: Queue)
    func getConfiguration() throws -> QuestionnaireConfiguration
    func getElements() throws -> [QuestionnaireElement]
    func getAnswersForElement(_ element: QuestionnaireElement) -> AnyHashable?
    func redirectTargetPage(for option: ElementOption) -> Int?
    func logicTargetPage(for option: ElementOption, name: String) -> Int?
    func goToNextPage() -> Bool
    func goToPreviousPage() -> Bool
    func goToPage(_ page: Int)
    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable)
    func removeAnswer(key: QuestionnaireElement?, value: AnyHashable)
}

final class NINQuestionnaireViewModelImpl: NINQuestionnaireViewModel {

    private let sessionManager: NINChatSessionManager
    private let queue: Queue
    private let views: [[QuestionnaireElement]]
    private var connector: QuestionnaireElementConnector!
    private(set) var answers: [String:AnyHashable]!

    // MARK: - NINQuestionnaireViewModel

    var pageNumber: Int = 0
    var previousPage: Int = 0
    var onErrorOccurred: ((Error) -> Void)?
    var onQuestionnaireFinished: ((Queue) -> Void)?
    var onSessionFinished: (() -> Void)?

    init(sessionManager: NINChatSessionManager, queue: Queue) {
        self.queue = queue
        self.sessionManager = sessionManager
        self.views = QuestionnaireElementConverter(configurations: sessionManager.siteConfiguration.preAudienceQuestionnaire!).elements
        self.connector = QuestionnaireElementConnectorImpl(configurations: sessionManager.siteConfiguration.preAudienceQuestionnaire!)
        self.answers = (try? self.extractGivenPreAnswers()) ?? [:]

        self.setupConnector(queue: queue)
    }

    private func setupConnector(queue: Queue) {
        self.connector.logicContainsTags = { [weak self] logic in
            self?.submitTags(logic?.tags ?? [])
        }
        self.connector.onCompleteTargetReached = { [weak self] logic in
            guard let target: (canJoin: Bool, queue: Queue?) = self?.canJoinGivenQueue(withID: logic?.queue ?? queue.queueID), let targetQueue = target.queue, target.canJoin else {
                self?.connector.onRegisterTargetReached?(logic); return
            }

            self?.finishQuestionnaire()
            self?.onQuestionnaireFinished?(targetQueue)
        }
        self.connector.onRegisterTargetReached = { [weak self] logic in
            self?.registerAudience(queueID: logic?.queue ?? queue.queueID) { error in
                if let error = error {
                    self?.onErrorOccurred?(error)
                } else {
                    self?.onSessionFinished?()
                }
            }
        }
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
}

extension NINQuestionnaireViewModelImpl {
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

    private func finishQuestionnaire() {
        self.sessionManager.preAudienceQuestionnaireMetadata = self.questionnaireAnswers
    }
}

// MARK: - NINQuestionnaireViewModel

extension NINQuestionnaireViewModelImpl {
    var questionnaireAnswers: NINLowLevelClientProps {
        NINLowLevelClientProps.initiate(metadata: self.answers)
    }

    func getConfiguration() throws -> QuestionnaireConfiguration {
        if let audienceQuestionnaire = self.sessionManager.siteConfiguration.preAudienceQuestionnaire?.filter({ $0.element != nil || $0.elements != nil }) {
            guard audienceQuestionnaire.count > self.pageNumber else { throw NINQuestionnaireException.invalidNumberOfQuestionnaires }

            return audienceQuestionnaire[self.pageNumber]
        }
        throw NINQuestionnaireException.invalidPage(self.pageNumber)
    }

    func getElements() throws -> [QuestionnaireElement] {
        guard self.views.count > self.pageNumber else { throw NINQuestionnaireException.invalidNumberOfViews }
        return self.views[self.pageNumber]
    }

    func getAnswersForElement(_ element: QuestionnaireElement) -> AnyHashable? {
        if let configuration = element.elementConfiguration, let value = self.answers[configuration.name] {
            return value
        }
        return nil
    }

    func redirectTargetPage(for option: ElementOption) -> Int? {
        do {
            return self.connector.findElementAndPageRedirect(for: option.value, in: try getConfiguration()).1
        } catch {
            return nil
        }
    }

    func logicTargetPage(for option: ElementOption, name: String) -> Int? {
        self.connector.findElementAndPageLogic(for: [name:AnyCodable(option.value)], in: self.answers).1
    }

    func submitAnswer(key: QuestionnaireElement?, value: AnyHashable) {
        if let configuration = key?.elementConfiguration {
            self.answers[configuration.name] = value
        }
    }

    func removeAnswer(key: QuestionnaireElement?, value: AnyHashable) {
        if let configuration = key?.elementConfiguration, let answer = self.answers[configuration.name], answer == value {
            self.answers.removeValue(forKey: configuration.name)
        }
    }

    func goToNextPage() -> Bool {
        if self.views.count > self.pageNumber + 1 {
            self.previousPage = self.pageNumber
            self.pageNumber += 1

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

    func goToPage(_ page: Int) {
        self.previousPage = self.pageNumber
        self.pageNumber = page
    }
}
