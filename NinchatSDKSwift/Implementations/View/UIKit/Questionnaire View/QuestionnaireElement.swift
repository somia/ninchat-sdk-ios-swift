//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable

protocol QuestionnaireElement: UIView {
    var configuration: QuestionnaireConfiguration? { get set }
    var height: CGFloat { get }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool)
    func shapeView()
}
extension QuestionnaireElement {
    var height: CGFloat { 0 }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideAssets(with: delegate, isPrimary: true)
    }
}

/// Questionnaire element with
///     - title
///     - options
protocol QuestionnaireElementWithTitleAndOptions: QuestionnaireElement {
    var title: UILabel { get }
    var view: UIView { get }
    var scaleToParent: Bool { get set }
    var onElementOptionFocused: ((ElementOption) -> Void)? { get set }

    func addElementViews()
    func layoutElementViews()
}
extension QuestionnaireElementWithTitleAndOptions {
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

    var height: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + CGFloat(4.0 * 8.0)
    }
}

/// Questionnaire buttons
protocol QuestionnaireElementHasButtons {
    var onNextButtonTapped: ((ButtonQuestionnaire) -> Void)? { get set }
    var onBackButtonTapped: ((ButtonQuestionnaire) -> Void)? { get set }
    var buttons: UIView { get }

    func addNavigationButtons()
    func layoutNavigationButtons()
    func shapeNavigationButtons()
    func shapeNavigationNext(button: UIButton, configuration: AnyCodable)
    func shapeNavigationBack(button: UIButton, configuration: AnyCodable)
}
extension QuestionnaireElementHasButtons where Self:QuestionnaireElementWithTitleAndOptions {
    func addNavigationButtons() {
        /// Must be called in `view.awakeFromNib()` function

        self.addSubview(buttons)
    }

    func layoutNavigationButtons() {
        view
            .deactivate(constraints: [.bottom])
        buttons
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self.view), isRelative: true)
            .fix(bottom: (8.0, self))
    }

    var height: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + CGFloat(self.buttons.height?.constant ?? 0) + CGFloat(5.0 * 8.0)
    }

    func shapeNavigationNext(button: UIButton, configuration: AnyCodable) {
        if let _ = configuration.value as? Bool {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .highlighted)
        } else if let title = configuration.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setBackgroundImage(UIColor.QBlueButtonNormal.toImage, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.white, for: .selected)
            button.setBackgroundImage(UIColor.QBlueButtonHighlighted.toImage, for: .highlighted)
        }
    }

    func shapeNavigationBack(button: UIButton, configuration: AnyCodable) {
        if let _ = configuration.value as? Bool {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .selected)
        } else if let title = configuration.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.QBlueButtonNormal, for: .normal)
            button.setBackgroundImage(nil, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.QBlueButtonHighlighted, for: .selected)
            button.setBackgroundImage(nil, for: .selected)
        }
    }
}
