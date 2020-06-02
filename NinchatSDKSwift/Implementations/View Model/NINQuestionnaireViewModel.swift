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

    init(sessionManager: NINChatSessionManager)
    func canJoinGivenQueue(withID id: String) -> (Bool, Queue?)
    func registerAudience(queueID: String, completion: @escaping (Error?) -> Void)
    func finishQuestionnaire()
    func getConfiguration() throws -> QuestionnaireConfiguration
    func getElements() throws -> [QuestionnaireElement]
    mutating func goToNextPage() -> Bool
    mutating func goToPreviousPage() -> Bool
    mutating func goToPage(_ page: Int)
    mutating func submitTags(_ tags: [String])
    mutating func submitAnswer(key: QuestionnaireElement?, value: AnyHashable)
    mutating func removeAnswer(key: QuestionnaireElement?, value: AnyHashable)
}

struct NINQuestionnaireViewModelImpl: NINQuestionnaireViewModel {

    private unowned let sessionManager: NINChatSessionManager
    private let views: [[QuestionnaireElement]]
    private var answers: [String:AnyHashable] = [:]

    // MARK: - NINQuestionnaireViewModel

    var pageNumber: Int = 0
    var previousPage: Int = 0

    init(sessionManager: NINChatSessionManager) {
        self.sessionManager = sessionManager
        self.views = QuestionnaireElementConverter(configurations: sessionManager.siteConfiguration.preAudienceQuestionnaire!).elements
    }

    func canJoinGivenQueue(withID id: String) -> (Bool, Queue?) {
        if let targetQueue = self.sessionManager.queues.first(where: { $0.queueID == id }) {
            return (!targetQueue.isClosed, targetQueue)
        }
        return (false, nil)
    }
}

extension NINQuestionnaireViewModelImpl {
    func registerAudience(queueID: String, completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.registerQuestionnaire(queue: queueID, answers: NINLowLevelClientProps.initiate(preQuestionnaireAnswers: self.answers), completion: completion)
        } catch {
            completion(error)
        }
    }

    func finishQuestionnaire() {
        self.sessionManager.preAudienceQuestionnaireMetadata = self.questionnaireAnswers
    }
}

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
}

extension NINQuestionnaireViewModelImpl {
    mutating func goToNextPage() -> Bool {
        if self.views.count > self.pageNumber + 1 {
            self.previousPage = self.pageNumber
            self.pageNumber += 1

            return true
        }
        return false
    }

    mutating func goToPreviousPage() -> Bool {
        if self.pageNumber > 0 {
            self.pageNumber = self.previousPage
            return true
        }
        return false
    }

    mutating func goToPage(_ page: Int) {
        self.previousPage = self.pageNumber
        self.pageNumber = page
    }
}

extension NINQuestionnaireViewModelImpl {
    mutating func submitTags(_ tags: [String]) {
        guard !tags.isEmpty else { return }

        self.answers["tags"] = tags.reduce(into: NINLowLevelClientStrings.initiate) { (result: inout NINLowLevelClientStrings, tag: String) in
            result.append(tag)
        }
    }

    mutating func submitAnswer(key: QuestionnaireElement?, value: AnyHashable) {
        if let configuration = key?.elementConfiguration {
            self.answers[configuration.name] = value
        }
    }

    mutating func removeAnswer(key: QuestionnaireElement?, value: AnyHashable) {
        if let configuration = key?.elementConfiguration, let answer = self.answers[configuration.name], answer == value {
            self.answers.removeValue(forKey: configuration.name)
        }
    }
}
