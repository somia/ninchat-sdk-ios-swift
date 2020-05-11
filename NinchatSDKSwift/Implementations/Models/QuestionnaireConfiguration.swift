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
            if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []), let questionnaire = try? JSONDecoder().decode(QuestionnaireConfiguration.self, from: data) {
                result.append(questionnaire)
            }
        }
    }
}

// MARK: - QuestionnaireConfiguration
struct QuestionnaireConfiguration: Codable {
    let name: String
    let type: String?
    let buttons: Buttons?
    let elements: [ElementQuestionnaire]?
    let logic: LogicQuestionnaire?
}

// MARK: - Buttons
struct Buttons: Codable {
    let back, next: Bool
}

// MARK: - Element
struct ElementQuestionnaire: Codable {
    let name: String
    let element: ElementType
    let label: String
    let options: [Option]?
    let redirects: [Redirect]?
    let type: InputElementType?
    let pattern: String?
    let required: Bool?
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
struct Option: Codable {
    let label, value: String
}

// MARK: - Redirect
struct Redirect: Codable {
    let pattern, target: String
}

// MARK: - ElementTypes
enum ElementType: String, Codable {
    case input
    case likert
    case radio
    case select
    case text
    case textarea
}

// MARK: - InputElementTypes
enum InputElementType: String, Codable {
    case text
    case checkbox
}