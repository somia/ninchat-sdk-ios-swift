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
            if dictionary["element"] is String, let element = try? JSONDecoder().decode(ElementQuestionnaire.self, from: data) {
                /// This is an `Element` object, no configuration else is embedded
                result.append(QuestionnaireConfiguration(name: nil, type: nil, buttons: nil, elements: [element], logic: nil))
            } else if dictionary["elements"] is Array<[String:Any]>, let questionnaire = try? JSONDecoder().decode(QuestionnaireConfiguration.self, from: data) {
                /// This is not an `Element` object, but a configuration one with elements in it
                result.append(questionnaire)
            }
        }
    }
}

// MARK: - QuestionnaireConfiguration
struct QuestionnaireConfiguration: Codable {
    let name: String?
    let type: QuestionnaireConfigurationType?
    let buttons: ButtonQuestionnaire?
    let elements: [ElementQuestionnaire]?
    let logic: LogicQuestionnaire?
}

// MARK: - Buttons
struct ButtonQuestionnaire: Codable {
    let back, next: AnyCodable
}

// MARK: - Element
struct ElementQuestionnaire: Codable, Equatable {
    let name: String
    let element: ElementType
    let label: String
    let options: [ElementOption]?
    let redirects: [ElementRedirect]?
    let type: InputElementType?
    let pattern: String?
    let required: Bool?

    static func ==(lhs: ElementQuestionnaire, rhs: ElementQuestionnaire) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Logic
struct LogicQuestionnaire: Codable {
    let and: Array<[String:AnyCodable]>?
    let or: Array<[String:AnyCodable]>?
    let target: String
    let tags: [String]

    func satisfy(_ keys: [String]) -> Bool {
        if self.and != nil {
            return self.and?
                    .compactMap({ $0 })
                    .reduce(into: []) { (result: inout [String], dictionary: [String:AnyCodable]) in
                        result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                    }
                    .filter({ !keys.contains($0) })
                    .count == 0
        }
        return self.or?.compactMap({ $0 })
                .reduce(into: []) { (result: inout [String], dictionary: [String:AnyCodable]) in
                    result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                }
                .filter({ keys.contains($0) })
                .count != 0
    }
}

// MARK: - Option
struct ElementOption: Codable {
    let label, value: String
}

// MARK: - Redirect
struct ElementRedirect: Codable {
    let pattern, target: String
}

// MARK: - QuestionnaireConfigurationTypes
enum QuestionnaireConfigurationType: String, Codable {
    case group
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

// MARK: - InputElementTypes
enum InputElementType: String, Codable {
    case text
    case checkbox
}

// MARK: - QuestionnaireButtonType
enum QuestionnaireButtonType {
    case next
    case back
}
