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
            configuration.elements?.compactMap { element -> QuestionnaireElement? in
                switch element.element {
                case .text:
                    let element: QuestionnaireElementText = generate(from: element)
                    return element
                case .select:
                    let element: QuestionnaireElementSelect = generate(from: element)
                    return element
                case .radio:
                    let element: QuestionnaireElementRadio = generate(from: element)
                    return element
                case .textarea:
                    let element: QuestionnaireElementTextArea = generate(from: element)
                    return element
                case .checkbox:
                    let element: QuestionnaireElementCheckbox = generate(from: element)
                    return element
                case .input:
                    if element.type == .text {
                        let element: QuestionnaireElementTextField = generate(from: element)
                        return element
                    }
                    return nil
                case .likert:
                    #warning("No view is defined yet!")
                    return nil
                }
            }
        }
    }
}

extension QuestionnaireElementConverter {
    func generate<T: QuestionnaireElement>(from configuration: ElementQuestionnaire) -> T {
        let element = T(frame: .zero)
        element.configuration = configuration
        return element
    }
}