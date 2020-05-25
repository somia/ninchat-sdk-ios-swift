//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable

protocol QuestionnaireElement: UIView {
    var index: Int { get set }
    var elementHeight: CGFloat { get }
    var questionnaireConfiguration: QuestionnaireConfiguration? { get set }

    func shapeView(_ configuration: QuestionnaireConfiguration?)
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool)
}
extension QuestionnaireElement {
    var elementHeight: CGFloat { 0 }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideAssets(with: delegate, isPrimary: true)
    }
}

/// Questionnaire element with
///     - title
///     - options
protocol QuestionnaireElementWithTitle: QuestionnaireElement {
    var title: UILabel { get }
    var view: UIView { get }
    var scaleToParent: Bool { get set }
    var onElementOptionTapped: ((ElementOption) -> Void)? { get set }

    func addElementViews()
    func layoutElementViews()
}
extension QuestionnaireElementWithTitle {
    var elementHeight: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + CGFloat(4.0 * 8.0)
    }

    func addElementViews() {
        /// Must be called in `view.awakeFromNib()` function
        self.addSubview(title)
        self.addSubview(view)
    }

    func layoutElementViews() {
        /// Must be called once subviews are added
        title
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self))
            .fix(height: title.intrinsicContentSize.height + 16.0)
        view
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, title), isRelative: true)
            .center(toX: self)
            .fix(width: self.width?.constant ?? self.bounds.width)
    }
}

/// Questionnaire buttons
///     - navigation buttons:
///         - next
///         - back
protocol QuestionnaireNavigationButtons {
    var buttons: UIView { get }
    var configuration: QuestionnaireConfiguration? { get set }
    var onNextButtonTapped: ((ButtonQuestionnaire) -> Void)? { get set }
    var onBackButtonTapped: ((ButtonQuestionnaire) -> Void)? { get set }

    func addNavigationButtons()
    func shapeNavigationButtons(_ configuration: QuestionnaireConfiguration?)
    func layoutNavigationButtons()
}
