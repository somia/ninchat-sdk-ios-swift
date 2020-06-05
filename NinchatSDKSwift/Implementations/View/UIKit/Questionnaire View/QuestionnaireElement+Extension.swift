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
        view.setTitle(option.label, for: .selected)
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
