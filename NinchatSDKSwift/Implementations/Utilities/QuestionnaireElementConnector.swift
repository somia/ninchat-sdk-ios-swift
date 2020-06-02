//
// Copyright (c) 27.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable

protocol QuestionnaireElementConnector {
    var logicContainsTags: ((LogicQuestionnaire?) -> Void)? { get set }
    var onRegisterTargetReached: ((LogicQuestionnaire?) -> Void)? { get set }
    var onCompleteTargetReached: ((LogicQuestionnaire?) -> Void)? { get set }

    init(configurations: [QuestionnaireConfiguration])
    func findElementAndPageRedirect(for input: String, in configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?)
    func findElementAndPageLogic(for dictionary: [String:AnyCodable]) -> ([QuestionnaireElement]?, Int?)
}

struct QuestionnaireElementConnectorImpl: QuestionnaireElementConnector {
    private let elements: [[QuestionnaireElement]]
    private let configurations: [QuestionnaireConfiguration]

    init(configurations: [QuestionnaireConfiguration]) {
        self.configurations = configurations
        self.elements = QuestionnaireElementConverter(configurations: configurations).elements
    }

    var logicContainsTags: ((LogicQuestionnaire?) -> Void)?
    var onRegisterTargetReached: ((LogicQuestionnaire?) -> Void)?
    var onCompleteTargetReached: ((LogicQuestionnaire?) -> Void)?

    /// Returns the element the given configuration associated to
    /// The function is called if the `findTargetRedirectConfiguration(from:)` or `findTargetLogicConfiguration(from:)` returns valid configuration
    internal func findTargetElement(for configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?) {
        (self.elements.first { $0.filter { $0.questionnaireConfiguration == configuration }.count != 0 }, self.elements.firstIndex { $0.filter { $0.questionnaireConfiguration == configuration }.count != 0 })
    }
}

// MARK: - QuestionnaireElementConnector 'redirect'

extension QuestionnaireElementConnectorImpl {
    func findElementAndPageRedirect(for input: String, in configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?) {
        if let redirect = self.findAssociatedRedirect(for: input, in: configuration) {
            if let configuration = self.findTargetRedirectConfiguration(from: redirect).0 {
                if let element = self.findTargetElement(for: configuration).0, let page = self.findTargetElement(for: configuration).1 {
                    return (element, page)
                }
            }
        }
        return (nil, nil)
    }

    /// Returns associated 'redirect' object for the given string
    /// The input could be either the 'name' variable in QuestionnaireConfiguration object
    /// Or 'value' in ElementOption object
    internal func findAssociatedRedirect(for input: String, in configuration: QuestionnaireConfiguration) -> ElementRedirect? {
        if let redirect = configuration.redirects?.first(where: { $0.pattern == input }) {
            return redirect
        }
        return nil
    }

    /// Returns the configuration the given 'redirect' points to.
    /// The function's input is derived from `findAssociatedRedirect(for:)` output
    internal func findTargetRedirectConfiguration(from element: ElementRedirect) -> (QuestionnaireConfiguration?, Int?) {
        (self.configurations.first { $0.name == element.target }, self.configurations.firstIndex { $0.name == element.target })
    }
}

// MARK: - QuestionnaireElementConnector 'logic'

extension QuestionnaireElementConnectorImpl {
    internal var logicList: [LogicQuestionnaire] {
        self.configurations.compactMap({ $0.logic })
    }

    func findElementAndPageLogic(for dictionary: [String:AnyCodable]) -> ([QuestionnaireElement]?, Int?) {
        if let blocks = self.findLogicBlocks(for: Array(dictionary.keys)), blocks.count > 0 {
            let satisfied: (bool: Bool, logic: LogicQuestionnaire?) = areSatisfied(logic: blocks, forKeyValue: dictionary)
            if satisfied.bool, let logic = satisfied.logic {
                if let tags = logic.tags, tags.count > 0 {
                    self.logicContainsTags?(logic)
                }
                
                if logic.target == "_register" {
                    self.onRegisterTargetReached?(logic)
                } else if logic.target == "_complete" {
                    self.onCompleteTargetReached?(logic)
                } else if let configuration = self.findTargetLogicConfiguration(from: logic).0 {
                    if let element = self.findTargetElement(for: configuration).0, let page = self.findTargetElement(for: configuration).1 {
                        return (element, page)
                    }
                }
            }
        }
        return (nil, nil)
    }

    /// Returns corresponded 'logic' blocks for given input
    /// The input is the 'key' in the object's dictionary
    internal func findLogicBlocks(for keys: [String]) -> [LogicQuestionnaire]? {
        let findInAnds = self.logicList.filter({ $0.andKeys?.filter({ keys.contains($0) }).count ?? 0 > 0 })
        let findInOrs = self.logicList.filter({ $0.orKeys?.filter({ keys.contains($0) }).count ?? 0 > 0 })

        let results = findInAnds + findInOrs
        return (results.count > 0) ? results : nil
    }

    /// Determines if the derived 'logic' blocks from the `findLogicBlocks(for:)` API are satisfied
    /// Returns corresponded 'logic' block for given key:value
    internal func areSatisfied(logic blocks: [LogicQuestionnaire], forKeyValue dictionary: [String:AnyCodable]) -> (Bool, LogicQuestionnaire?) {
        let satisfiedBlocks = blocks.filter({ $0.satisfy(Array(dictionary.keys)) })
        if let theBlock = satisfiedBlocks
                .first(where: {
                    let dictionaryValues: Array<AnyCodable> = Array(dictionary.values)
                    if let andValuesFiltered = $0.andValues?.filter({ dictionaryValues.contains($0) }) {
                        return andValuesFiltered.count > 0
                    }
                    if let orValuesFiltered = $0.orValues?.filter({ dictionaryValues.contains($0) }) {
                        return orValuesFiltered.count > 0
                    }
                    return false
                }) {
            return (true, theBlock)
        }
        return (false, nil)
    }

    /// Returns the configuration the given 'logic' points to.
    /// The function is called if the `areSatisfied(logic:values:)` returns the satisfied logic
    internal func findTargetLogicConfiguration(from logic: LogicQuestionnaire) -> (QuestionnaireConfiguration?, Int?) {
        (self.configurations.first { $0.name == logic.target }, self.configurations.firstIndex { $0.name == logic.target })
    }
}
