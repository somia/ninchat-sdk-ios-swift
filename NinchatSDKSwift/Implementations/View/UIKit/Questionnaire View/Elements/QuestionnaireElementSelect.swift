//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementSelect: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireOptionSelectableElement {

    fileprivate var heightValue: CGFloat = 45.0
    var normalBackgroundColor: UIColor! = .white
    var selectedBackgroundColor: UIColor! = .white

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var isShown: Bool? {
        didSet {
            self.isUserInteractionEnabled = isShown ?? true
        }
    }
    var scaleToParent: Bool = false
    var questionnaireStyle: QuestionnaireStyle?
    var questionnaireConfiguration: QuestionnaireConfiguration? {
        didSet {
            if let elements = questionnaireConfiguration?.elements {
                self.shapeView(elements[index])
            } else {
                self.shapeView(questionnaireConfiguration)
            }

            self.decorateView()
        }
    }
    var elementConfiguration: QuestionnaireConfiguration?
    var elementHeight: CGFloat = 0

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideTitle(delegate: delegate)

        normalBackgroundColor = delegate?.override(questionnaireAsset: .selectDeselectedBackground) ?? .white
        selectedBackgroundColor = delegate?.override(questionnaireAsset: .selectSelectedBackground) ?? .white
        selectedOption.textColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorSelectUnselectText) ?? .QGrayButton

        /// On scrolling the table, the `selectedOption` highlight status changes back to 'false'
        /// We should reset it to avoid breaking the UI
        selectedOption.isHighlighted = (selectionIndicator.tint != selectedOption.textColor) && (self.isCompleted ?? false)
        selectedOption.highlightedTextColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorSelectSelectedText) ?? .QBlueButtonNormal
    }

    // MARK: - QuestionnaireSettable

    func updateSetAnswers(_ answer: AnyHashable?, configuration: QuestionnaireConfiguration?, state: QuestionnaireSettableState) {
        guard let option = self.elementConfiguration?.options?.first(where: { $0.value == answer }) else { return }
        self.select(option: option, state: state)
        self.updateBorder()
    }

    // MARK: - QuestionnaireOptionSelectableElement

    var onElementOptionSelected: ((QuestionnaireElement, ElementOption) -> ())?
    var onElementOptionDeselected: ((QuestionnaireElement, ElementOption) -> ())?

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var view: UIView = {
        UIView(frame: .zero)
    }()
    private(set) lazy var selectedOption: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var selectionIndicator: UIImageView = {
        UIImageView(image: UIImage(named: "icon_select_option", in: .SDKBundle, compatibleWith: nil))
    }()
    private var dialogueIsShown = false

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
        self.view.addSubview(selectedOption)
        self.view.addSubview(selectionIndicator)
        self.decorateView()

        self.selectedOption.text = "Select".localized
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onMenuTapped(_:))))
    }

    private func decorateView() {
        if self.subviews.count > 0 {
            self.layoutElementViews()

            selectedOption
                .fix(leading: (8.0, self.view), trailing: (8.0, self.view))
                .fix(top: (0.0, self.view), bottom: (0.0, self.view))
            selectionIndicator
                .fix(width: 15.0, height: 15.0)
                .fix(trailing: (15.0, self.view))
                .center(toY: self.view)
        }
    }

    // MARK: - User actions

    @objc
    private func onMenuTapped(_ sender: UITapGestureRecognizer) {
        self.endEditing(true)
        self.showOptions()
    }
}

extension QuestionnaireElementSelect {
    private func showOptions() {
        guard let options = self.elementConfiguration?.options?.compactMap({ $0.label }), options.count > 0 else { fatalError("There is no option to be shown!") }
        if dialogueIsShown { return }

        self.dialogueIsShown = true
        ChoiceDialogue.showDialogue(withOptions: options) { [weak self] result in
            self?.dialogueIsShown = false

            switch result {
            case .cancel:
                guard let option = self?.elementConfiguration?.options?.first(where: { $0.label == self?.selectedOption.text }) else { return }
                self?.deselect(option: option)
            case .select(let index):
                guard let option = self?.elementConfiguration?.options?[index] else { fatalError("Unable to pick selected option") }
                self?.select(option: option, state: .set)
            }
            self?.updateBorder()
        }
    }

    private func select(option: ElementOption, state: QuestionnaireSettableState) {
        self.selectedOption.isHighlighted = true
        self.selectedOption.text = option.label
        self.view.backgroundColor = selectedBackgroundColor

        switch state {
        case .set:
            self.onElementOptionSelected?(self, option)
        case .nothing:
            debugger("Do nothing for Select element")
        }

    }

    func deselect(option: ElementOption) {
        self.selectedOption.isHighlighted = false
        self.selectedOption.text = "Select".localized
        self.view.backgroundColor = normalBackgroundColor
        self.onElementOptionDeselected?(self, option)
    }
}

extension QuestionnaireElementSelect: QuestionnaireElement {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        if self.didShapedView { return }

        self.elementConfiguration = configuration
        self.shapeTitle(configuration)
        self.view.backgroundColor = self.normalBackgroundColor
        self.selectedOption.font = .ninchat
        self.selectedOption.textAlignment = .left
        self.selectedOption.textColor = .QBlueButtonNormal
        self.selectedOption.highlightedTextColor = .QGrayButton
        self.selectionIndicator.contentMode = .scaleAspectFit
        self.updateBorder()
        self.adjustConstraints(viewHeight: self.heightValue)
    }
}

extension QuestionnaireElementSelect: QuestionnaireHasBorder {
    var isCompleted: Bool? {
        self.selectedOption.text != "Select".localized
    }

    func updateBorder() {
        self.selectionIndicator.tint = self.selectedOption.isHighlighted ? self.selectedOption.highlightedTextColor : self.selectedOption.textColor
        self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: self.selectionIndicator.tint ?? .QGrayButton)
    }
}
