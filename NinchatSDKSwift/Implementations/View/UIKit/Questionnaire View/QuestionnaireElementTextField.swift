//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementTextField: UIView, QuestionnaireElement {

    // MARK: - QuestionnaireElement

    var configuration: ElementQuestionnaire? {
        didSet {
            self.shapeView()
        }
    }
    var onElementFocused: ((QuestionnaireElement) -> Void)?
    var onElementDismissed: ((QuestionnaireElement) -> Void)?

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) { }

    // MARK: - UIView life-cycle

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var input: UITextField = {
        UITextField(frame: .zero)
    }()

    var isCompleted: Bool! = false {
        didSet {
            self.shapeView()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.addSubview(title)
        self.addSubview(input)
        self.input.addTarget(self, action: #selector(self.onEditingStarted(_:)), for: .editingDidBegin)
        self.input.addTarget(self, action: #selector(self.onEditingFinished(_:)), for: .editingDidEnd)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        title
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (8.0, self))
            .fix(height: self.title.intrinsicContentSize.height + 16.0)
        input
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self.title), isRelative: true)
            .fix(bottom: (8.0, self))
            .fix(height: 45.0)
    }

    // MARK: - User actions

    @objc
    private func onEditingStarted(_ sender: UITextField) {
        self.onElementFocused?(self)
    }

    @objc
    private func onEditingFinished(_ sender: UITextField) {
        if configuration?.required ?? false, sender.text?.isEmpty ?? true {
            self.isCompleted = false
        } else if let pattern = configuration?.pattern, let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            self.isCompleted = regex.matches(in: sender.text!, range: NSRange(location: 0, length: sender.text!.count)).count > 0
        }
        self.onElementDismissed?(self)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementTextField {
    func shapeView() {
        self.title.text = self.configuration?.label
        self.title.textAlignment = .left
        self.title.font = .ninchat

        self.input.backgroundColor = .clear
        self.input.borderStyle = .none
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