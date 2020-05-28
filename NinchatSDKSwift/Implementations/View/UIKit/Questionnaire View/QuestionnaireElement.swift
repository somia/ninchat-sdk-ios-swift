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
    var elementConfiguration: QuestionnaireConfiguration? { get }

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
    associatedtype View: UIView
    var view: View { get }
    var title: UILabel { get }
    var scaleToParent: Bool { get set }

    func addElementViews()
    func layoutElementViews()
}
extension QuestionnaireElementWithTitle {
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

    func shapeTitle(_ configuration: QuestionnaireConfiguration?) {
        self.title.font = .ninchat
        self.title.numberOfLines = 0
        self.title.textAlignment = .left
        self.title.lineBreakMode = .byWordWrapping
        self.title.text = configuration?.label
    }
}

/// Add focus/dismiss closure for applicable elements (e.g. textarea, input)
protocol QuestionnaireFocusableElement {
    var onElementFocused: ((QuestionnaireElement) -> Void)? { get set }
    var onElementDismissed: ((QuestionnaireElement) -> Void)? { get set }
}

/// Add select/deselect closure for applicable elements (e.g. radio, checkbox)
protocol QuestionnaireOptionSelectableElement {
    var onElementOptionSelected: ((ElementOption) -> Void)? { get set }
    var onElementOptionDeselected: ((ElementOption) -> Void)? { get set }

    func deselect(option: ElementOption)
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

/// Add 'Done' button to keyboards to dismiss applicable elements (e.g. textarea, input)
protocol QuestionnaireHasDoneButton {
    func doneButton(selector: Selector) -> UIToolbar
}
extension QuestionnaireHasDoneButton {
    func doneButton(selector: Selector) -> UIToolbar {
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: selector)
        let doneToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.items = [flexSpace, doneBtn]
        doneToolbar.barStyle = .default
        return doneToolbar
    }
}
