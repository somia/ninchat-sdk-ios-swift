//
// Copyright (c) 27.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireElementConnector {
    init(configurations: [QuestionnaireConfiguration])
    func findElementAndPage(for input: String, in configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?)
}

struct QuestionnaireElementConnectorImpl: QuestionnaireElementConnector {
    private let elements: [[QuestionnaireElement]]
    private let configurations: [QuestionnaireConfiguration]

    init(configurations: [QuestionnaireConfiguration]) {
        self.configurations = configurations
        self.elements = QuestionnaireElementConverter(configurations: configurations).elements
    }

    func findElementAndPage(for input: String, in configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?) {
        if let redirect = self.findAssociatedRedirect(for: input, in: configuration) {
            if let configuration = self.findTargetConfiguration(from: redirect).0 {
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
    internal func findTargetConfiguration(from element: ElementRedirect) -> (QuestionnaireConfiguration?, Int?) {
        (self.configurations.first { $0.name == element.target }, self.configurations.firstIndex { $0.name == element.target })
    }

    /// Returns the element the given configuration associated to
    /// The function is called if the `findTargetConfiguration(from:)` returns valid configuration
    internal func findTargetElement(for configuration: QuestionnaireConfiguration) -> ([QuestionnaireElement]?, Int?) {
        (self.elements.first { $0.filter { $0.questionnaireConfiguration == configuration }.count != 0 }, self.elements.firstIndex { $0.filter { $0.questionnaireConfiguration == configuration }.count != 0 })
    }
}
