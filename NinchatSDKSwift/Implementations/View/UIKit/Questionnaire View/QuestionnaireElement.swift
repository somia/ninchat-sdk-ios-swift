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
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?)
}
extension QuestionnaireElement {
    var elementHeight: CGFloat { 0 }
}

/// Questionnaire element with
///     - title
///     - options
protocol QuestionnaireElementWithTitle: QuestionnaireElement {
    associatedtype View: UIView
    var view: View { get }
    var title: UILabel { get }
    var scaleToParent: Bool { get set }
    var didShapedView: Bool { get }

    func addElementViews()
    func layoutElementViews()
    func overrideTitle(delegate: NINChatSessionInternalDelegate?)
}
extension QuestionnaireElementWithTitle {
    /// To prevent duplicate shaping functions
    var didShapedView: Bool {
        self.elementConfiguration != nil
    }

    func addElementViews() {
        /// Must be called in `view.awakeFromNib()` function

        title.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 16.0
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
            .fix(width: self.bounds.width)
        view.leading?.priority = .almostRequired
        view.trailing?.priority = .almostRequired
    }

    func overrideTitle(delegate: NINChatSessionInternalDelegate?) {
        self.title.textColor = delegate?.override(questionnaireAsset: .titleTextColor) ?? UIColor.black
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
    var onNextButtonTapped: (() -> Void)? { get set }
    var onBackButtonTapped: (() -> Void)? { get set }

    func addNavigationButtons()
    func shapeNavigationButtons(_ configuration: QuestionnaireConfiguration?)
    func layoutNavigationButtons()
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?)
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

/// Shape border for applicable elements (e.g. textarea, input)
protocol QuestionnaireHasBorder: QuestionnaireElementWithTitle {
    var isCompleted: Bool? { get }
    func updateBorder()
}
extension QuestionnaireHasBorder {
    func updateBorder() {
        guard self.view is UITextField || self.view is UITextView else { fatalError("Call only on `UITextView` and `UITextField` types") }

        if self.elementConfiguration?.required ?? false {
            self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: (self.isCompleted ?? true) ? .QGrayButton : .QRedBorder)
        } else {
            self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: .QGrayButton)
        }
    }
}

/// Make the applicable questionnaire item able to get pre-set answers
protocol QuestionnaireSettable {
    var presetAnswer: AnyHashable? { get set }
}
