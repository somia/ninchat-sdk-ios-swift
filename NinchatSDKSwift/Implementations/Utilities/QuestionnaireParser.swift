//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/// The utility aims to convert `QuestionnaireConfiguration` into corresponded UIViews and Logic blocks
/// It is injected with configurations and return an array of [QuestionnaireItemsConverterTypes]

struct QuestionnaireItems {
    var elements: [QuestionnaireElement]?
    var logic: LogicQuestionnaire?
}

struct QuestionnaireParser {
    private let configurations: [QuestionnaireConfiguration]
    private let style: QuestionnaireStyle
    var items: [QuestionnaireItems] = []

    init(configurations: [QuestionnaireConfiguration], style: QuestionnaireStyle) {
        self.configurations = configurations
        self.style = style

        self.items = self.configurations.reduce(into: [], { (result: inout [QuestionnaireItems], configuration: QuestionnaireConfiguration) in
            func getView(from element: ElementType, index: Int) -> QuestionnaireElement? {
                switch element {
                case .text:
                    return generate(from: configuration, index: index, ofType: QuestionnaireElementText.self)
                case .select:
                    return generate(from: configuration, index: index, ofType: QuestionnaireElementSelect.self)
                case .radio:
                    return generate(from: configuration, index: index, ofType: QuestionnaireElementRadio.self)
                case .textarea:
                    return generate(from: configuration, index: index, ofType: QuestionnaireElementTextArea.self)
                case .checkbox:
                    return generate(from: configuration, index: index, ofType: QuestionnaireElementCheckbox.self)
                case .input:
                    return generate(from: configuration, index: index, ofType: QuestionnaireElementTextField.self)
                case .likert:
                    return generate(from: configuration, index: index, ofType: QuestionnaireElementLikert.self)
                }
            }

            if let logic = configuration.logic {
                result.append(QuestionnaireItems(elements: nil, logic: logic))
            } else if let element = configuration.element, let view = getView(from: element, index: 0) {
                result.append(QuestionnaireItems(elements: [view], logic: nil))
            } else if let elements = configuration.elements?.compactMap({ element -> QuestionnaireElement? in
                if let type = element.element, let index = configuration.elements?.firstIndex(of: element) {
                    return getView(from: type, index: index)
                }
                return nil
            }) {
                result.append(QuestionnaireItems(elements: elements, logic: nil))
            }
        })
    }
}

extension QuestionnaireParser {
    func generate<T: QuestionnaireElement>(from configuration: QuestionnaireConfiguration, index: Int, ofType: T.Type) -> T {
        let view = T(frame: .zero)
        view.index = index
        view.questionnaireStyle = style
        view.questionnaireConfiguration = configuration

        return view
    }
}
