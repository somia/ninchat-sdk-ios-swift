//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementTextField: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireHasBorder, QuestionnaireFocusableElement {

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var scaleToParent: Bool = true
    var questionnaireConfiguration: QuestionnaireConfiguration? {
        didSet {
            if let elements = questionnaireConfiguration?.elements {
                self.shapeView(elements[index])
            } else {
                self.shapeView(questionnaireConfiguration)
            }
        }
    }
    var elementConfiguration: QuestionnaireConfiguration?
    var elementHeight: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + CGFloat(5.0 * 8.0)
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideTitle(delegate: delegate)
        self.view.textColor = delegate?.override(questionnaireAsset: .textInputColor) ?? .black
    }

    // MARK: - QuestionnaireSettable

    var presetAnswer: AnyHashable? {
        didSet {
            if let answer = self.presetAnswer as? String {
                self.view.text = answer
                self.textFieldDidEndEditing(self.view)
            }
        }
    }

    // MARK: - QuestionnaireHasBorder

    var isCompleted: Bool! {
        didSet {
            self.updateBorder()
        }
    }

    // MARK: - QuestionnaireFocusableElement

    var onElementFocused: ((QuestionnaireElement) -> Void)?
    var onElementDismissed: ((QuestionnaireElement) -> Void)?

    // MARK: - Subviews

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var view: UITextField = {
        UITextField(frame: .zero)
    }()

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        self.initiateView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initiateView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initiateView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.decorateView()
        self.layoutIfNeeded()
    }

    // MARK: - View Setup

    private func initiateView() {
        self.addElementViews()
        self.view.delegate = self
        self.view.inputAccessoryView = self.doneButton(selector: #selector(self.onDoneButtonTapped(_:)))
    }

    private func decorateView() {
        if self.view.subviews.count > 0 {
            self.layoutElementViews()
        }
    }
}

extension QuestionnaireElementTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.onElementFocused?(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty, let pattern = self.elementConfiguration?.pattern, let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            self.isCompleted = regex.matches(in: text, range: NSRange(location: 0, length: text.count)).count > 0
        } else {
            self.isCompleted = !(self.elementConfiguration?.required ?? false)
        }
        self.onElementDismissed?(self)
    }
}

extension QuestionnaireElementTextField: QuestionnaireHasDoneButton {
    @objc
    private func onDoneButtonTapped(_ sender: Any) {
        self.view.endEditing(true)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementTextField {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        if self.didShapedView { return }

        self.elementConfiguration = configuration
        self.shapeTitle(configuration)
        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.borderStyle = .none
        self.view.keyboardType = keyboardType(configuration)
        self.view.font = .ninchat
        self.view.fix(height: 45.0)
        self.updateBorder()
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
