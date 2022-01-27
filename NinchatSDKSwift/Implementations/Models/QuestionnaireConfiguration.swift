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
    let label, pattern, href: String?
    let type: QuestionnaireConfigurationType?
    let buttons: ButtonQuestionnaire?
    let logic: LogicQuestionnaire?
    let redirects: [ElementRedirect]?
    let element: ElementType?
    let inputMode: QuestionnaireInputMode?
    let required: Bool?
    let options: [ElementOption]?
    let elements: [QuestionnaireConfiguration]?

    enum CodingKeys: String, CodingKey {
        case name, label, pattern, href, type, buttons, logic, redirects, element, required, options, elements
        case inputMode = "inputmode"
    }

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
    let and: Array<[String:AnyCodable]>?
    let or: Array<[String:AnyCodable]>?
    let target: String
    let queueId: String?
    let tags: [String]?

    var andKeys: [String]? {
        self.and?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [String], dictionary: [String:AnyCodable]) in
                    result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                }
    }
    var orKeys: [String]? {
        self.or?
                .compactMap({ $0 })
                .reduce(into: []) { (result: inout [String], dictionary: [String:AnyCodable]) in
                    result.append(contentsOf: dictionary.keys.compactMap({ $0 }))
                }
    }

    func satisfy(dictionary: [String:AnyHashable]) -> Bool {
        if let ands = self.and, ands.count > 0 {
            return ands.first(where: {
                guard let targets = dictionary.filter(based: $0, keys: self.andKeys ?? []) else { return false }
                return targets.count == $0.keys.count
            }) != nil
        } else if let ors = self.or, ors.count > 0 {
            return ors.first(where: {
                guard let targets = dictionary.filter(based: $0, keys: self.orKeys ?? []) else { return false }
                return targets.count != 0
            }) != nil
        }
        /// if there is no "and"/"or", the block satisfies everything
        return true
    }
}

// MARK: - Option
struct ElementOption: Codable, Equatable {
    var label: String?
    var value: AnyHashable! {
        set { _value = AnyCodable(newValue) }
        get { _value?.value as? AnyHashable }
    }
    var _value: AnyCodable!
    let href: String?

    enum CodingKeys: String, CodingKey {
        case _value = "value"
        case label, href
    }

    init(label: String, value: AnyHashable?, href: String? = nil) {
        self.label = label
        self.href = href
        self.value = value
    }

    static func ==(lhs: ElementOption, rhs: ElementOption) -> Bool {
        lhs.label == rhs.label
    }
}

// MARK: - Redirect
struct ElementRedirect: Codable {
    let target: String
    var pattern: AnyHashable? {
        set { _pattern = AnyCodable(newValue) }
        get { _pattern?.value as? AnyHashable }
    }
    var _pattern: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case _pattern = "pattern"
        case target
    }
    
    init(pattern: AnyHashable?, target: String) {
        self.target = target
        self.pattern = pattern
    }
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
    case a
}

// MARK: - QuestionnaireButtonType
enum QuestionnaireButtonType {
    case next
    case back
}

// MARK: - InputMode
enum QuestionnaireInputMode: String, Codable {
    case text
    case email
    case numeric
    case decimal
    case tel
    case url
}
extension QuestionnaireInputMode {
    var keyboard: UIKeyboardType {
        switch self {
        case .text:
            return .default
        case .email:
            return .emailAddress
        case .numeric:
            return .numberPad
        case .decimal:
            return .decimalPad
        case .tel:
            return .phonePad
        case .url:
            return .URL
        }
    }
}
