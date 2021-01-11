//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireElement: UIView {
    var index: Int { get set }
    var isShown: Bool? { get set }
    var elementHeight: CGFloat { get }
    var questionnaireStyle: QuestionnaireStyle? { get set }
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
    private var requiredIndicator: String {
        "   *required"
    }
    private var requiredIndicatorAlpha: CGFloat {
        0.7
    }

    /// To prevent duplicate shaping functions
    var didShapedView: Bool {
        self.elementConfiguration != nil
    }

    var padding: CGFloat {
        guard let title = self.title.text, !title.isEmpty else { return 8.0 }
        return self.questionnaireStyle == .form ? 32.0 : 40.0
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
            .fix(height: title.intrinsicContentSize.height + self.padding)
        view
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, title), isRelative: true)
            .center(toX: self)
            .fix(width: self.bounds.width)
        view.leading?.priority = .almostRequired
        view.trailing?.priority = .almostRequired
    }

    func overrideTitle(delegate: NINChatSessionInternalDelegate?) {
        guard let titleComponents = self.title.text?.components(separatedBy: self.requiredIndicator) else { return }

        let attributedString = NSMutableAttributedString(string: self.title.text!)
        let defaultColor = delegate?.override(questionnaireAsset: .titleTextColor) ?? UIColor.black
        if let restComponent = titleComponents.filter({ !$0.isEmpty }).first, restComponent != self.requiredIndicator {
            attributedString.applyUpdates(to: restComponent, color: defaultColor)
        }
        if titleComponents.count > 1 {
            attributedString.applyUpdates(to: self.requiredIndicator, color: defaultColor.withAlphaComponent(self.requiredIndicatorAlpha), font: .subtitleNinchat)
        }
        self.title.attributedText = attributedString
    }

    func shapeTitle(_ configuration: QuestionnaireConfiguration?) {
        self.title.font = .ninchat
        self.title.numberOfLines = 0
        self.title.textAlignment = .left
        self.title.lineBreakMode = .byWordWrapping

        if let text = configuration?.label {
            self.title.text = text + ((configuration?.required ?? false) ? self.requiredIndicator : "")
        }
    }

    func isCompleted(text: String?) -> Bool {
        if let text = text, !text.isEmpty, let pattern = self.elementConfiguration?.pattern, let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            return regex.matches(in: text, range: NSRange(location: 0, length: text.count)).count > 0
        } else if let text = text, self.elementConfiguration?.required ?? false  {
            return !text.isEmpty
        }
        return true
    }
}


/// Add focus/dismiss closure for applicable elements (e.g. textarea, input)
protocol QuestionnaireFocusableElement {
    var onElementFocused: ((QuestionnaireElement) -> Void)? { get set }
    var onElementDismissed: ((QuestionnaireElement) -> Void)? { get set }

    func clearAll()
}
extension QuestionnaireFocusableElement where Self:QuestionnaireElementTextArea {
    func clearAll() {
        self.view.text = ""
    }
}
extension QuestionnaireFocusableElement where Self:QuestionnaireElementTextField {
    func clearAll() {
        self.view.text = ""
    }
}


/// Add select/deselect closure for applicable elements (e.g. radio, checkbox)
protocol QuestionnaireOptionSelectableElement {
    var onElementOptionSelected: ((QuestionnaireElement, ElementOption) -> Void)? { get set }
    var onElementOptionDeselected: ((QuestionnaireElement, ElementOption) -> Void)? { get set }

    func deselect(option: ElementOption)
    func deselectAll()
}
extension QuestionnaireOptionSelectableElement where Self:QuestionnaireElement {
    func deselectAll() {
        self.elementConfiguration?.options?.compactMap({ $0 }).forEach({ self.deselect(option: $0) })
    }
}

/// Questionnaire buttons
///     - navigation buttons:
///         - next
///         - back
protocol QuestionnaireNavigationButtons {
    var buttons: UIStackView { get }
    var configuration: QuestionnaireConfiguration? { get set }
    var shouldShowNextButton: Bool! { get set }
    var shouldShowBackButton: Bool! { get set }
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
protocol QuestionnaireHasBorder {
    var isCompleted: Bool? { get }
    func updateBorder()
}
extension QuestionnaireHasBorder where Self:QuestionnaireElementWithTitle {
    func updateBorder() {
        guard self.view is UITextField || self.view is UITextView else { fatalError("Call only on `UITextView` and `UITextField` types") }
        self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: (self.isCompleted ?? true) ? .QGrayButton : .QRedBorder)
    }
}

/// Make the applicable questionnaire item able to get pre-set answers
enum QuestionnaireSettableState {
    case set
    case nothing
}
protocol QuestionnaireSettable {
    /// `configuration` parameter is needed for grouped checkboxes where the answer has to be distinguished
    func updateSetAnswers(_ answer: AnyHashable?, configuration: QuestionnaireConfiguration?, state: QuestionnaireSettableState)
}
