//
// Copyright (c) 26.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension QuestionnaireElementWithTitle where View:UITextField {
    func shapeTextField(_ configuration: QuestionnaireConfiguration?) {
        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.borderStyle = .none
        self.view.keyboardType = keyboardType(configuration)
        self.view.font = .ninchat
        self.view.fix(height: 45.0)
    }

    private func keyboardType(_ configuration: QuestionnaireConfiguration?) -> UIKeyboardType {
        switch configuration?.pattern ?? "" {
        case "^(1[0-9]|[0-9])$":
            return .numberPad
        case "^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$":
            return .emailAddress
        case "^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\\s\\./0-9]*$":
            return .phonePad
        default:
            return .default
        }
    }
}

extension QuestionnaireElementWithTitle where View:UITextView {
    func shapeTextView(_ configuration: QuestionnaireConfiguration?) {
        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.font = .ninchat
        self.view.fix(height: 98.0)
    }
}

extension QuestionnaireElementWithTitle where View:UIView, Self:QuestionnaireOptionSelectableElement {
    func shapeRadioView(_ configuration: QuestionnaireConfiguration?) {
        var upperView: UIView?
        configuration?.options?.forEach { [unowned self] option in
            let button = self.generateButton(for: option, tag: (configuration?.options?.firstIndex(of: option))!)
            self.layoutButton(button, upperView: &upperView)
        }
    }

    private func generateButton(for option: ElementOption, tag: Int) -> Button {
        let view = Button(frame: .zero) { [weak self] button in
            self?.applySelection(to: button)
            button.isSelected ? self?.onElementOptionSelected?(option) : self?.onElementOptionDeselected?(option)
        }

        view.tag = tag + 1
        view.setTitle(option.label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(option.label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        view.updateTitleScale()
        view.roundButton()

        return view
    }

    private func layoutButton(_ button: UIView, upperView: inout UIView?) {
        self.view.addSubview(button)

        if self.scaleToParent {
            button.fix(leading: (8.0, self.view), trailing: (8.0, self.view))
            button.leading?.priority = .required
            button.trailing?.priority = .required
        } else if self.width?.constant ?? 0 < self.intrinsicContentSize.width + 32.0 {
            button.fix(width: button.intrinsicContentSize.width + 32.0)
        }
        if let upperView = upperView {
            button.fix(top: (8.0, upperView), isRelative: true)
        } else {
            button.fix(top: (8.0, self.view), isRelative: false)
        }
        button
            .fix(height: max(45.0, button.intrinsicContentSize.height + 16.0))
            .center(toX: self.view)

        if let height = self.view.height {
            height.constant += ((button.height?.constant ?? 0) + 8.0)
        } else {
            self.view.fix(height: (button.height?.constant ?? 0) + 16.0)
        }

        upperView = button
    }

    private func applySelection(to button: UIButton) {
        self.view.subviews.compactMap({ $0 as? Button }).forEach { button in
            button.isSelected = false
            (button as Button).roundButton()
        }
        button.isSelected = true
        (button as? Button)?.roundButton()
    }
}

extension QuestionnaireElementWithTitle where View:UIView, Self:QuestionnaireOptionSelectableElement {
    func shapeCheckbox(_ configuration: QuestionnaireConfiguration?) {
        var upperView: UIView?
        configuration?.options?.forEach { [unowned self] option in
            let icon = self.generateIcon(tag: (configuration?.options?.firstIndex(of: option))!)
            let button = self.generateButton(for: option, icon: icon, tag: (configuration?.options?.firstIndex(of: option))!)
            self.layout(icon: icon.1, within: icon.0)
            self.layout(button: button, icon: icon.0, upperView: &upperView)
        }
    }

    private func generateButton(for option: ElementOption, icon: (UIView, UIImageView), tag: Int) -> Button {
        let view = Button(frame: .zero) { [weak self] button in
            button.isSelected = !button.isSelected
            icon.0.round(radius: 23.0 / 2, borderWidth: 2.0, borderColor: button.isSelected ? .QBlueButtonNormal : .QGrayButton)
            icon.1.isHighlighted = button.isSelected
            button.isSelected ? self?.onElementOptionSelected?(option) : self?.onElementOptionDeselected?(option)
        }

        view.tag = tag + 100
        view.setTitle(option.label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(option.label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        view.titleLabel?.font = .ninchat
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.textAlignment = .left
        view.titleLabel?.lineBreakMode = .byWordWrapping

        return view
    }

    private func generateIcon(tag: Int) -> (UIView, UIImageView) {
        let imgViewContainer = UIView(frame: .zero)
        imgViewContainer.backgroundColor = .clear
        imgViewContainer.isUserInteractionEnabled = false
        imgViewContainer.isExclusiveTouch = false

        let image = UIImageView(image: nil, highlightedImage: UIImage(named: "icon_checkbox_selected", in: .SDKBundle, compatibleWith: nil))
        image.tag = tag + 200

        return (imgViewContainer, image)
    }

    private func layout(icon: UIImageView, within view: UIView) {
        view.addSubview(icon)

        icon
            .fix(top: (5.0, view), bottom: (5.0, view))
            .fix(leading: (5.0, view), trailing: (5.0, view))
    }

    private func layout(button: Button, icon: UIView, upperView: inout UIView?) {
        self.view.addSubview(button)
        self.view.addSubview(icon)

        /// Layout icon
        icon
                .fix(leading: (0.0, self.view))
                .fix(width: 23.0, height: 23.0)
                .center(toY: button)
                .round(radius: 23.0 / 2, borderWidth: 2.0, borderColor: .QGrayButton)
        icon.leading?.priority = .required
        icon.width?.priority = .required
        icon.height?.priority = .required

        /// Layout button
        if let upperView = upperView {
            button.fix(top: (2.0, upperView), isRelative: true)
        } else {
            button.fix(top: (0.0, self.view), isRelative: false)
        }
        button
                .fix(trailing: (8.0, self.view), relation: .greaterThan)
                .fix(leading: (0.0, icon), isRelative: true)
                .fix(width: button.intrinsicContentSize.width + 32.0)
                .fix(height: max(32.0, button.intrinsicContentSize.height))
        button.leading?.priority = .required

        /// Layout parent view
        if let height = self.view.height {
            height.constant += button.height?.constant ?? 0
        } else {
            self.view.fix(height: (button.height?.constant ?? 0) + 16.0)
        }

        upperView = button
    }
}

extension QuestionnaireElementWithTitle where View:UIView {
    func shapeSelect() {
        self.view.backgroundColor = .clear
        self.view.fix(height: 45.0)
    }
}
