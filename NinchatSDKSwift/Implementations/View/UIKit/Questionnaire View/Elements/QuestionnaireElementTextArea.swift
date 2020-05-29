//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementTextArea: UIView, QuestionnaireElementWithTitle, QuestionnaireHasBorder, QuestionnaireFocusableElement {

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
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + CGFloat(3.0 * 8.0)
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
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
    private(set) lazy var view: UITextView = {
        UITextView(frame: .zero)
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

extension QuestionnaireElementTextArea: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.onElementFocused?(self)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text, !text.isEmpty, let pattern = self.elementConfiguration?.pattern, let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            self.isCompleted = regex.matches(in: text, range: NSRange(location: 0, length: text.count)).count > 0
        }
        self.onElementDismissed?(self)
    }
}

extension QuestionnaireElementTextArea: QuestionnaireHasDoneButton {
    @objc
    private func onDoneButtonTapped(_ sender: Any) {
        self.view.endEditing(true)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementTextArea {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.shapeTitle(configuration)

        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.font = .ninchat
        self.view.fix(height: 98.0)

        self.elementConfiguration = configuration
        if self.isCompleted == nil {
            self.isCompleted = !(configuration?.required ?? true)
        }
        self.updateBorder()
    }
}
