//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable

protocol QuestionnaireElement: UIView {
    var index: Int { get set }
    var height: CGFloat { get }
    var configuration: QuestionnaireConfiguration? { get set }

    func shapeView(_ configuration: QuestionnaireConfiguration?)
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool)
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
protocol QuestionnaireElementWithTitle: QuestionnaireElement {
    var title: UILabel { get }
    var view: UIView { get }
    var scaleToParent: Bool { get set }
    var onElementOptionTapped: ((ElementOption) -> Void)? { get set }

    func addElementViews()
    func layoutElementViews()
}
extension QuestionnaireElementWithTitle {
    var height: CGFloat {
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
protocol QuestionnaireElementWithNavigationButtons: QuestionnaireElementWithTitle {
    var buttons: UIView { get }
    var onNextButtonTapped: ((ButtonQuestionnaire) -> Void)? { get set }
    var onBackButtonTapped: ((ButtonQuestionnaire) -> Void)? { get set }

    func addNavigationButtons()
    func shapeNavigationButtons(_ configuration: QuestionnaireConfiguration?)
    func layoutNavigationButtons()
}
extension QuestionnaireElementWithNavigationButtons {
    var height: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + CGFloat(self.buttons.height?.constant ?? 0) + CGFloat(5.0 * 8.0)
    }

    func addNavigationButtons() {
        /// Must be called in `view.awakeFromNib()` function
        self.addSubview(buttons)
    }

    func layoutNavigationButtons() {
        buttons
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self.view), isRelative: true)
            .fix(height: 45.0)
    }

    func shapeNavigationButtons(_ configuration: QuestionnaireConfiguration?) {
        guard let configuration = configuration?.buttons, configuration.hasValidButtons else { return }
        if configuration.hasValidBackButton {
            let button = Button(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onBackButtonTapped?(configuration)
            }
            self.layoutButton(button, configuration: configuration, type: .back)
        }
        if configuration.hasValidNextButton {
            let button = Button(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onNextButtonTapped?(configuration)
            }
            self.layoutButton(button, configuration: configuration, type: .next)
        }
    }

    private func layoutButton(_ button: UIButton, configuration: ButtonQuestionnaire, type: QuestionnaireButtonType) {
        self.buttons.addSubview(button)

        button.titleLabel?.font = .ninchat
        button.imageEdgeInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        button
                .fix(width: max(80.0, self.intrinsicContentSize.width + 32.0), height: 45.0)
                .round(radius: 45.0 / 2, borderWidth: 1.0, borderColor: .QBlueButtonNormal)
        if type == .back {
            self.shapeNavigationBack(button: button, configuration: configuration.back)

        } else if type == .next {
            self.shapeNavigationNext(button: button, configuration: configuration.next)
        }
    }

    private func shapeNavigationNext(button: UIButton, configuration: AnyCodable) {
        if let _ = configuration.value as? Bool {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .highlighted)
        } else if let title = configuration.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.white, for: .selected)
        }

        button.setBackgroundImage(UIColor.QBlueButtonNormal.toImage, for: .normal)
        button.setBackgroundImage(UIColor.QBlueButtonHighlighted.toImage, for: .highlighted)
        button
            .fix(trailing: (16.0, self.buttons))
            .center(toY: self.buttons)
    }

    private func shapeNavigationBack(button: UIButton, configuration: AnyCodable) {
        if let _ = configuration.value as? Bool {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .selected)
        } else if let title = configuration.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.QBlueButtonNormal, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.QBlueButtonHighlighted, for: .selected)
        }
        button.setBackgroundImage(nil, for: .normal)
        button.setBackgroundImage(nil, for: .selected)
        button
            .fix(leading: (16.0, self.buttons))
            .center(toY: self.buttons)
    }
}
