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
    func findElementAndPageRedirect(for input: AnyHashable, in configuration: QuestionnaireConfiguration, autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?)
    func findElementAndPageLogic(logic block: LogicQuestionnaire, in answers: [String:AnyHashable], autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?)
    mutating func appendElements(_ elements: [QuestionnaireItems], configurations: [QuestionnaireConfiguration])
}

struct QuestionnaireElementConnectorImpl: QuestionnaireElementConnector {
    internal var items: [QuestionnaireItems] = []
    internal var configurations: [QuestionnaireConfiguration] = []

    init(configurations: [QuestionnaireConfiguration], style: QuestionnaireStyle) {
        self.configurations = configurations
        self.items = QuestionnaireParser(configurations: configurations, style: style).items
    }

    var logicContainsTags: ((LogicQuestionnaire?) -> Void)?
    var onRegisterTargetReached: ((LogicQuestionnaire?, ElementRedirect?, _ autoApply: Bool) -> Void)?
    var onCompleteTargetReached: ((LogicQuestionnaire?, ElementRedirect?, _ autoApply: Bool) -> Void)?

    /// Returns the element the given configuration associated to
    /// The function is called if the `findTargetRedirectConfiguration(from:)` or `findTargetLogicConfiguration(from:)` returns valid configuration
    internal func findTargetElement(for configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?) {
        let targetElement = self.items.compactMap({ $0.elements }).first(where: { $0.filter({ $0.questionnaireConfiguration == configuration }).count != 0 })
        for counter in 0..<items.count {
            guard let elements = items[counter].elements?.filter({ $0.questionnaireConfiguration == configuration }), elements.count != 0 else { continue }
            return (elements, counter)
        }
        return (nil,nil)
    }

    mutating func appendElements(_ item: [QuestionnaireItems], configurations: [QuestionnaireConfiguration]) {
        self.items.append(contentsOf: item)
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
    func findElementAndPageRedirect(for input: AnyHashable, in configuration: QuestionnaireConfiguration, autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?) {
        if let redirect = self.findAssociatedRedirect(for: input, in: configuration) {
            if redirect.target == "_register", performClosures {
                self.onRegisterTargetReached?(nil, redirect, autoApply); return (nil, -1)
            }
            if redirect.target == "_complete", performClosures {
                self.onCompleteTargetReached?(nil, redirect, autoApply); return (nil, -1)
            }
            if let configuration = self.findTargetRedirectConfiguration(from: redirect).0 {
                return self.findTargetElement(for: configuration)
            }
        }
        return (nil, nil)
    }

    /// Returns associated 'redirect' object for the given string
    /// The input could be either the 'name' variable in QuestionnaireConfiguration object
    /// Or 'value' in ElementOption object
    internal func findAssociatedRedirect(for input: AnyHashable, in configuration: QuestionnaireConfiguration) -> ElementRedirect? {
        /// The input is 'String'
        if let strInput = input as? String,
           let redirect = configuration
                .redirects?
                .filter({ ($0.pattern as? String) != nil }) /// filter only redirects with 'String' patterns
                .first(where: { strInput.extractRegex(withPattern: $0.pattern as! String)?.count ?? 0 > 0 }) {
            return redirect
        } else if let redirect = configuration.redirects?.first(where: { $0.pattern ?? AnyHashable("") == input }) {
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
    /// The function aims to extract associated index and QuestionnaireElement object for a given LogicQuestionnaire
    /// - Parameters:
    ///   - logic: The logic block that is under lookup.
    ///   - answers: The dictionary of currently saved answers that has to be looked through
    ///   - autoApply: The variable declares if the '_register'/'_complete' closures are automatically applied or not.
    ///   - performClosures: The variable declares if the '_register'/'_complete' closures has to be performed or not.
    /// - Returns: Returns associated index and QuestionnaireElement for the given input in the given answers. If the
        /// index == nil -> No associated elements found
        /// index == -1 -> No associated elements found, but the '_register' or '_complete' block is found.
    func findElementAndPageLogic(logic block: LogicQuestionnaire, in answers: [String:AnyHashable], autoApply: Bool, performClosures: Bool) -> ([QuestionnaireElement]?, Int?) {
        if block.satisfy(dictionary: answers) {
            if let tags = block.tags, tags.count > 0 {
                self.logicContainsTags?(block)
            }

            if block.target == "_register", performClosures {
                self.onRegisterTargetReached?(block, nil, autoApply); return (nil, -1)
            }
            if block.target == "_complete", performClosures {
                self.onCompleteTargetReached?(block, nil, autoApply); return (nil, -1)
            }
            if block.target == "_exit", performClosures {
                return (nil, -2)
            }
            if let configuration = self.findTargetLogicConfiguration(from: block).0 {
                return self.findTargetElement(for: configuration)
            }
        }
        return (nil, nil)
    }

    /// Returns the configuration the given 'logic' points to.
    /// The function is called if the `areSatisfied(logic:values:)` returns the satisfied logic
    internal func findTargetLogicConfiguration(from logic: LogicQuestionnaire) -> (QuestionnaireConfiguration?, Int?) {
        (self.configurations.first { $0.name == logic.target }, self.configurations.firstIndex { $0.name == logic.target })
    }
}
