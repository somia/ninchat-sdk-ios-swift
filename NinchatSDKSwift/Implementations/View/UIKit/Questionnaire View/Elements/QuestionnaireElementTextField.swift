//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementTextField: UIView, QuestionnaireElement {

    var isCompleted: Bool! = false {
        didSet {
            self.shapeView(configuration)
        }
    }

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var configuration: QuestionnaireConfiguration? {
        didSet {
            self.shapeView(configuration)
        }
    }
    var onElementFocused: ((QuestionnaireElement) -> Void)?
    var onElementDismissed: ((QuestionnaireElement) -> Void)?

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
    }

    // MARK: - Subviews

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var input: UITextField = {
        UITextField(frame: .zero)
    }()

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        self.addSubview(title)
        self.addSubview(input)
        self.input.delegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.deactivate(constraints: [.height])
        title
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self))
            .fix(height: self.title.intrinsicContentSize.height + 16.0)
        input
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self.title), isRelative: true)
            .fix(bottom: (8.0, self))
            .fix(height: 45.0)
    }
}

extension QuestionnaireElementTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.onElementFocused?(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if configuration?.required ?? false, textField.text?.isEmpty ?? true {
            self.isCompleted = false
        } else if let pattern = configuration?.pattern, let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive), let text = textField.text {
            self.isCompleted = regex.matches(in: text, range: NSRange(location: 0, length: text.count)).count > 0
        }
        self.onElementDismissed?(self)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementTextField {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.title.text = self.configuration?.label
        self.title.textAlignment = .left
        self.title.font = .ninchat

        self.input.backgroundColor = .clear
        self.input.borderStyle = .none
        self.input.font = .ninchat
        self.input.round(radius: 6.0, borderWidth: 1.0, borderColor: self.isCompleted ? .QGrayButton : .QRedBorder)

        switch self.configuration?.name.lowercased() {
        case "phone":
            self.input.keyboardType = .phonePad
        case "email":
            self.input.keyboardType = .emailAddress
        default:
            self.input.keyboardType = .default
        }
    }
}