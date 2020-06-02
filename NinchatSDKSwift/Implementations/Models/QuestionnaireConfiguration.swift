//
// Copyright (c) 11.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import AnyCodable

// MARK: - Questionnaire
struct AudienceQuestionnaire {
    var questionnaireConfiguration: [QuestionnaireConfiguration]?
    init(from configuration: [AnyHashable : Any]?, for key: String) {
        guard let configuration = configuration, let questionnaireConfigurations = configuration[key] as? Array<[String:AnyHashable]> else { return }
        questionnaireConfiguration = questionnaireConfigurations.reduce(into: []) { (result: inout [QuestionnaireConfiguration], dictionary: [String: AnyHashable]) in
            guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return }
            do {
                let questionnaire = try JSONDecoder().decode(QuestionnaireConfiguration.self, from: data)
                result.append(questionnaire)
            } catch {
                #if DEBUG
                    fatalError(error.localizedDescription)
                #endif
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
    let back, next: AnyCodable
    var hasValidButtons: Bool {
        self.hasValidBackButton || self.hasValidNextButton
    }
    var hasValidBackButton: Bool {
        isValid(self.back)
    }
    var hasValidNextButton: Bool {
        isValid(self.next)
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
    let and: Array<[String:AnyCodable]>?
    let or: Array<[String:AnyCodable]>?
    let target: String
    let queue: String?
    let tags: [String]?

    var andKeys: [String]? {
        self.and?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [String], dictionary: [String:AnyCodable]) in
                    result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                }
    }
    var andValues: [AnyCodable]? {
        self.and?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [AnyCodable], dictionary: [String:AnyCodable]) in
                    result.append(contentsOf: dictionary.values.compactMap({ $0 }))
                }
    }

    var orKeys: [String]? {
        self.or?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [String], dictionary: [String:AnyCodable]) in
                    result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                }
    }
    var orValues: [AnyCodable]? {
        self.or?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [AnyCodable], dictionary: [String:AnyCodable]) in
                    result.append(contentsOf: dictionary.values.compactMap({ $0 }))
                }
    }

    func satisfy(_ keys: [String]) -> Bool {
        if self.and != nil {
            return self.andKeys?
                    .filter({ !keys.contains($0) })
                    .count == 0
        }
        return self.orKeys?
                .filter({ keys.contains($0) })
                .count != 0
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
    let pattern, target: String
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
