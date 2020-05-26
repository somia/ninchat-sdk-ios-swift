//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementTextField: UIView, QuestionnaireElementWithTitle, QuestionnaireFocusableElement {

    internal var configuration: QuestionnaireConfiguration!
    var isCompleted: Bool! {
        didSet {
            self.updateBorder()
        }
    }

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
    var elementHeight: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + CGFloat(5.0 * 8.0)
    }
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
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
    }

    private func decorateView() {
        if self.view.subviews.count > 0 {
            self.layoutElementViews()
        }
    }
}

extension QuestionnaireElementTextField {
    internal func updateBorder() {
        if self.configuration.required ?? false {
            self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: self.isCompleted ? .QGrayButton : .QRedBorder)
        } else {
            self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: .QGrayButton)
        }
    }
}

extension QuestionnaireElementTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.onElementFocused?(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty, let pattern = self.configuration.pattern, let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            self.isCompleted = regex.matches(in: text, range: NSRange(location: 0, length: text.count)).count > 0
        }
        self.onElementDismissed?(self)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementTextField {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.title.font = .ninchat
        self.title.numberOfLines = 0
        self.title.textAlignment = .left
        self.title.lineBreakMode = .byWordWrapping
        self.title.text = configuration?.label

        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.borderStyle = .none
        self.view.font = .ninchat
        self.view.fix(height: 45.0)

        self.configuration = configuration
        self.updateBorder()
    }
}
