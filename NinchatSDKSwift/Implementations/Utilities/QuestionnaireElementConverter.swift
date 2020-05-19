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
            func getView(from element: ElementType) -> QuestionnaireElement? {
                switch element {
                case .text:
                    return generate(from: configuration, ofType: QuestionnaireElementText.self)
                case .select:
                    return generate(from: configuration, ofType: QuestionnaireElementSelect.self)
                case .radio:
                    return generate(from: configuration, ofType: QuestionnaireElementRadio.self)
                case .textarea:
                    return generate(from: configuration, ofType: QuestionnaireElementTextArea.self)
                case .checkbox:
                    return generate(from: configuration, ofType: QuestionnaireElementCheckbox.self)
                case .input:
                    return generate(from: configuration, ofType: QuestionnaireElementTextField.self)
                case .likert:
                    #warning("No view is defined yet!")
                    return nil
                }
            }

            if let element = configuration.element, let view = getView(from: element) {
                return [view]
            }
            return configuration.elements?.compactMap { element -> QuestionnaireElement? in
                if let element = element.element {
                    return getView(from: element)
                }
                return nil
            }
        }
    }
}

extension QuestionnaireElementConverter {
    func generate<T: QuestionnaireElement>(from configuration: QuestionnaireConfiguration, ofType: T.Type) -> T {
        let element = T(frame: .zero)
        element.configuration = configuration
        return element
    }
}