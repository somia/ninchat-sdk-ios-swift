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

    init(sessionManager: NINChatSessionManager)
    func registerAudience(queueID: String, completion: @escaping ((Error?) -> Void))
    func finishQuestionnaire()

    var questionnaireAnswers: NINLowLevelClientProps { get }
    func getConfiguration() throws -> QuestionnaireConfiguration
    func getElements() throws -> [QuestionnaireElement]

    mutating func goToNextPage() -> Bool
    mutating func goToPreviousPage() -> Bool
    mutating func goToPage(_ page: Int)

    mutating func submitAnswer(key: QuestionnaireElement?, value: Any)
    mutating func removeAnswer(key: QuestionnaireElement?, value: Any)
}

struct NINQuestionnaireViewModelImpl: NINQuestionnaireViewModel {

    private unowned let sessionManager: NINChatSessionManager
    private let views: [[QuestionnaireElement]]
    private var answers: [String:AnyCodable] = [:]

    // MARK: - NINQuestionnaireViewModel

    var pageNumber: Int = 0
    var previousPage: Int = 0

    init(sessionManager: NINChatSessionManager) {
        self.sessionManager = sessionManager
        self.views = QuestionnaireElementConverter(configurations: sessionManager.siteConfiguration.preAudienceQuestionnaire!).elements
    }

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
    mutating func submitAnswer(key: QuestionnaireElement?, value: Any) {
        if let configuration = key?.elementConfiguration {
            self.answers[configuration.name] = AnyCodable(value)
        }
    }

    mutating func removeAnswer(key: QuestionnaireElement?, value: Any) {
        if let configuration = key?.elementConfiguration, let answer = self.answers[configuration.name], answer == AnyCodable(value) {
            self.answers.removeValue(forKey: configuration.name)
        }
    }
}
