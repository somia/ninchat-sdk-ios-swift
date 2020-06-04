//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/// The utility aims to convert `QuestionnaireConfiguration` into corresponded UIViews
/// The utility is injected with configurations and return an array of [QuestionnaireElement]

struct QuestionnaireElementConverter {
    private let configurations: [QuestionnaireConfiguration]

    init(configurations: [QuestionnaireConfiguration]) {
        self.configurations = configurations
    }

    var elements: [[QuestionnaireElement]] {
        self.configurations.compactMap { configuration in
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

            if let element = configuration.element, let view = getView(from: element, index: 0) {
                return [view]
            }
            return configuration.elements?.compactMap { element -> QuestionnaireElement? in
                if let type = element.element, let index = configuration.elements?.firstIndex(of: element) {
                    return getView(from: type, index: index)
                }
                return nil
            }
        }
    }
}

extension QuestionnaireElementConverter {
    func generate<T: QuestionnaireElement>(from configuration: QuestionnaireConfiguration, index: Int, ofType: T.Type) -> T {
        let view = T(frame: .zero)
        view.index = index
        view.questionnaireConfiguration = configuration

        return view
    }
}
