//
// Copyright (c) 4.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementLikert: QuestionnaireElementRadio {
    private let options = ["Strongly agree".localized, "Agree".localized, "OK".localized, "Disagree".localized, "Strongly disagree".localized]
    private var option: (String, [String]) -> ElementOption = { value, options in
        ElementOption(label: value, value: "\(options.firstIndex(of: value)! + 1)")
    }

    override var questionnaireConfiguration: QuestionnaireConfiguration? {
        didSet {
            if let elements = questionnaireConfiguration?.elements {
                self.shapeView(elements[index])
            } else {
                self.shapeView(questionnaireConfiguration)
            }

            self.decorateView()
        }
    }
}

extension QuestionnaireElementLikert {
    func shapeLikertView() {
        var upperView: UIView?
        self.options.forEach { [unowned self] string in
            let option = self.option(string, self.options)
            let button = self.generateButton(for: option, tag: Int(option.value)!)
            self.layoutButton(button, upperView: &upperView)
        }
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementLikert {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.elementConfiguration = configuration

        self.shapeTitle(configuration)
        guard self.view.subviews.count == 0 else { return }
        self.shapeLikertView()
    }
}
