//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementTextArea: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireHasBorder, QuestionnaireFocusableElement {

    fileprivate var heightValue: CGFloat = 100.0
    private var answerUpdateWorker: DispatchWorkItem?

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var isShown: Bool? {
        didSet {
            self.isUserInteractionEnabled = isShown ?? true
        }
    }
    var scaleToParent: Bool = true
    var questionnaireStyle: QuestionnaireStyle?
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
    var elementHeight: CGFloat = 0

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideTitle(delegate: delegate)
        self.view.textColor = delegate?.override(questionnaireAsset: .textInputColor) ?? .black
    }

    // MARK: - QuestionnaireSettable

    func updateSetAnswers(_ answer: AnyHashable?, configuration: QuestionnaireConfiguration?, state: QuestionnaireSettableState) {
        guard let answer = answer as? String else { return }
        self.view.text = answer

        switch state {
        case .set:
            self.textViewDidEndEditing(self.view)
        case .nothing:
            debugger("Do nothing for TextArea element")
        }

    }

    // MARK: - QuestionnaireHasBorder

    var isCompleted: Bool? {
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
        self.decorateView()

        self.view.delegate = self
        self.view.inputAccessoryView = self.doneButton(selector: #selector(self.onDoneButtonTapped(_:)))
    }

    private func decorateView() {
        if self.subviews.count > 0 {
            self.layoutElementViews()
        }
    }
}

extension QuestionnaireElementTextArea: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.onElementFocused?(self)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        defer { self.onElementDismissed?(self) }
        self.isCompleted = isCompleted(text: textView.text)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.answerUpdateWorker?.cancel()
        self.answerUpdateWorker = DispatchWorkItem { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.isCompleted = weakSelf.isCompleted(text: (textView.text ?? "") + text)
            weakSelf.onElementDismissed?(weakSelf)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: self.answerUpdateWorker!)

        return true
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
        if self.didShapedView { return }

        self.elementConfiguration = configuration
        self.shapeTitle(configuration)
        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.font = .ninchat
        self.updateBorder()
        self.adjustConstraints(viewHeight: self.heightValue)
    }
}
