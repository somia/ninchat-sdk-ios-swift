//
// Copyright (c) 11.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import AnyCodable

enum AudienceQuestionnaireType {
    case pre
    case post
}

// MARK: - Questionnaire
struct AudienceQuestionnaire {
    var questionnaireConfiguration: [QuestionnaireConfiguration]?
    init(from questionnaireConfigurations: Array<[String:AnyHashable]>?) {
        questionnaireConfiguration = questionnaireConfigurations?.reduce(into: []) { (result: inout [QuestionnaireConfiguration], dictionary: [String: AnyHashable]) in
            guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return }
            do {
                let questionnaire = try JSONDecoder().decode(QuestionnaireConfiguration.self, from: data)
                result.append(questionnaire)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}

// MARK: - QuestionnaireConfiguration
struct QuestionnaireConfiguration: Codable, Equatable {
    let name: String
    let label, pattern: String?
    let type: QuestionnaireConfigurationType?
    let buttons: ButtonQuestionnaire?
    let logic: LogicQuestionnaire?
    let redirects: [ElementRedirect]?
    let element: ElementType?
    let required: Bool?
    let options: [ElementOption]?
    let elements: [QuestionnaireConfiguration]?

    static func ==(lhs: QuestionnaireConfiguration, rhs: QuestionnaireConfiguration) -> Bool {
        if let elements_lhs = lhs.elements, let elements_rhs = rhs.elements {
            return elements_lhs == elements_rhs
        }
        return lhs.name == rhs.name
    }
}

// MARK: - Buttons
struct ButtonQuestionnaire: Codable {
    let back, next: AnyCodable?
    var hasValidButtons: Bool {
        self.hasValidBackButton || self.hasValidNextButton
    }
    var hasValidBackButton: Bool {
        if let button = self.back {
            return isValid(button)
        }
        return true
    }
    var hasValidNextButton: Bool {
        if let button = self.next {
            return isValid(button)
        }
        return true
    }

    // MARK: - Private helper

    private func isValid(_ button: AnyCodable) -> Bool {
        if let bool = button.value as? Bool {
            return bool
        } else if let string = button.value as? String {
            return !string.isEmpty
        }
        return false
    }
}

// MARK: - Logic
struct LogicQuestionnaire: Codable {
    let and: Array<[String:String]>?
    let or: Array<[String:String]>?
    let target: String
    let queue: String?
    let tags: [String]?

    var andKeys: [String]? {
        self.and?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [String], dictionary: [String:String]) in
                    result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                }
    }
    var orKeys: [String]? {
        self.or?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [String], dictionary: [String:String]) in
                    result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                }
    }

    func satisfy(dictionary: [String:String]) -> Bool {
        if let ands = self.and, ands.count > 0 {
            return ands.first(where: { dictionary.filter(based: $0, keys: self.andKeys ?? [])?.count == $0.keys.count }) != nil
        } else if let ors = self.or, ors.count > 0 {
            return ors.first(where: { dictionary.filter(based: $0, keys: self.orKeys ?? [])?.count != 0 }) != nil
        }
        return false
    }
}

// MARK: - Option
struct ElementOption: Codable, Equatable {
    let label, value: String

    static func ==(lhs: ElementOption, rhs: ElementOption) -> Bool {
        lhs.label == rhs.label
    }
}

// MARK: - Redirect
struct ElementRedirect: Codable {
    let pattern: String?
    let target: String
}

// MARK: - QuestionnaireConfigurationTypes
enum QuestionnaireConfigurationType: String, Codable {
    case group
    case text
}

// MARK: - ElementTypes
enum ElementType: String, Codable {
    case input
    case likert
    case radio
    case select
    case text
    case textarea
    case checkbox
}

// MARK: - QuestionnaireButtonType
enum QuestionnaireButtonType {
    case next
    case back
}
