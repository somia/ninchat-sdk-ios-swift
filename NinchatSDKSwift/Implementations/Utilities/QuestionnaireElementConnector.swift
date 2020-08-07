//
// Copyright (c) 27.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireElementConnector {
    var logicContainsTags: ((LogicQuestionnaire?) -> Void)? { get set }
    var onRegisterTargetReached: ((LogicQuestionnaire?, ElementRedirect?, _ autoApply: Bool) -> Void)? { get set }
    var onCompleteTargetReached: ((LogicQuestionnaire?, ElementRedirect?, _ autoApply: Bool) -> Void)? { get set }

    init(configurations: [QuestionnaireConfiguration], style: QuestionnaireStyle)
    func findElementAndPageRedirect(for input: String, in configuration: QuestionnaireConfiguration, autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?)
    func findElementAndPageLogic(for dictionary: [String:String], in answers: [String:AnyHashable], autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?)
    mutating func appendElement(elements: [QuestionnaireElement], configurations: [QuestionnaireConfiguration])
}

struct QuestionnaireElementConnectorImpl: QuestionnaireElementConnector {
    private var elements: [[QuestionnaireElement]] = []
    private var configurations: [QuestionnaireConfiguration] = []

    init(configurations: [QuestionnaireConfiguration], style: QuestionnaireStyle) {
        self.configurations = configurations
        self.elements = QuestionnaireElementConverter(configurations: configurations, style: style).elements
    }

    var logicContainsTags: ((LogicQuestionnaire?) -> Void)?
    var onRegisterTargetReached: ((LogicQuestionnaire?, ElementRedirect?, _ autoApply: Bool) -> Void)?
    var onCompleteTargetReached: ((LogicQuestionnaire?, ElementRedirect?, _ autoApply: Bool) -> Void)?

    /// Returns the element the given configuration associated to
    /// The function is called if the `findTargetRedirectConfiguration(from:)` or `findTargetLogicConfiguration(from:)` returns valid configuration
    internal func findTargetElement(for configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?) {
        (self.elements.first { $0.filter { $0.questionnaireConfiguration == configuration }.count != 0 }, self.elements.firstIndex { $0.filter { $0.questionnaireConfiguration == configuration }.count != 0 })
    }

    mutating func appendElement(elements: [QuestionnaireElement], configurations: [QuestionnaireConfiguration]) {
        self.elements.append(elements)
        self.configurations.append(contentsOf: configurations)
    }
}

// MARK: - QuestionnaireElementConnector 'redirect'

extension QuestionnaireElementConnectorImpl {
    /// The function aims to extract associated index and QuestionnaireElement object for a given ElementRedirect
    /// - Parameters:
    ///   - input: The value that has to be looked up in the given configuration to find associated index and element
    ///   - configuration: The configuration that holds ElementRedirect object
    ///   - autoApply: The variable declares if the '_register'/'_complete' closures are automatically applied or not.
    ///   - performClosures: The variable declares if the '_register'/'_complete' closures has to be performed or not.
    /// - Returns: Returns associated index and QuestionnaireElement for given configuration. If the
        /// index == nil -> No associated elements found
        /// index == -1 -> No associated elements found, but the '_register' or '_complete' block is found.
    func findElementAndPageRedirect(for input: String, in configuration: QuestionnaireConfiguration, autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?) {
        if let redirect = self.findAssociatedRedirect(for: input, in: configuration) {
            if redirect.target == "_register", performClosures {
                self.onRegisterTargetReached?(nil, redirect, autoApply); return (nil, -1)
            }
            if redirect.target == "_complete", performClosures {
                self.onCompleteTargetReached?(nil, redirect, autoApply); return (nil, -1)
            }
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
        if let redirect = configuration.redirects?.first(where: { input.extractRegex(withPattern: $0.pattern ?? "")?.count ?? 0 > 0 }) {
            return redirect
        } else if let redirect = configuration.redirects?.first(where: { $0.pattern ?? "" == input }) {
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

    /// The function aims to extract associated index and QuestionnaireElement object for a given LogicQuestionnaire
    /// - Parameters:
    ///   - dictionary: The dictionary that is supposed to point to a valid element. Both the keys and values must match with at least one logic block.
    ///   - answers: The dictionary of currently saved answers that has to be looked through
    ///   - autoApply: The variable declares if the '_register'/'_complete' closures are automatically applied or not.
    ///   - performClosures: The variable declares if the '_register'/'_complete' closures has to be performed or not.
    /// - Returns: Returns associated index and QuestionnaireElement for the given input in the given answers. If the
        /// index == nil -> No associated elements found
        /// index == -1 -> No associated elements found, but the '_register' or '_complete' block is found.
    func findElementAndPageLogic(for dictionary: [String:String], in answers: [String:AnyHashable], autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?) {
        if let blocks = self.findLogicBlocks(for: Array(dictionary.keys)), blocks.count > 0 {
            let satisfied: (bool: Bool, logic: LogicQuestionnaire?) = areSatisfied(logic: blocks, forAnswers: answers)
            if satisfied.bool, let logic = satisfied.logic {
                if let tags = logic.tags, tags.count > 0 {
                    self.logicContainsTags?(logic)
                }

                if logic.target == "_register", performClosures {
                    self.onRegisterTargetReached?(logic, nil, autoApply); return (nil, -1)
                }
                if logic.target == "_complete", performClosures {
                    self.onCompleteTargetReached?(logic, nil, autoApply); return (nil, -1)
                }
                if let configuration = self.findTargetLogicConfiguration(from: logic).0 {
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
    internal func areSatisfied(logic blocks: [LogicQuestionnaire], forAnswers answers: [String:AnyHashable]) -> (Bool, LogicQuestionnaire?) {
        if let theBlock = blocks.first(where: { $0.satisfy(dictionary: answers.filter({ $0.value is String }) as! [String:String] ) }) {
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
