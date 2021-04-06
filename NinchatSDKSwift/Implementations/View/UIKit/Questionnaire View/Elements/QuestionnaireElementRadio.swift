//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireExitElement {
    var isExitElement: Bool { set get }
}

class QuestionnaireElementRadio: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireOptionSelectableElement, QuestionnaireExitElement {

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

            self.decorateView()
        }
    }
    var elementConfiguration: QuestionnaireConfiguration?
    var elementHeight: CGFloat = 0

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideTitle(delegate: delegate)
        self.view.subviews.compactMap({ $0 as? Button }).forEach({ $0.overrideQuestionnaireAsset(with: delegate, isPrimary: $0.isSelected) })
    }

    // MARK: - QuestionnaireSettable

    func updateSetAnswers(_ answer: AnyHashable?, configuration: QuestionnaireConfiguration?, state: QuestionnaireSettableState) {
        guard let option = self.elementConfiguration?.options?.first(where: { $0.value == answer }),
              let button = self.view.subviews.compactMap({ $0 as? Button }).first(where: { $0.titleLabel?.text == option.label })
            else { return }

        switch state {
        case .set:
            button.closure?(button)
        case .nothing:
            debugger("Do nothing for Radio element")
        }
    }

    // MARK: - QuestionnaireOptionSelectableElement

    var onElementOptionSelected: ((QuestionnaireElement, ElementOption) -> ())?
    var onElementOptionDeselected: ((QuestionnaireElement, ElementOption) -> ())?

    func deselect(option: ElementOption) {
        guard let tag = self.elementConfiguration?.options?.firstIndex(where: { $0.label == option.label }) else { return }
        (self.view.viewWithTag(tag + 1) as? Button)?.isSelected = false
        (self.view.viewWithTag(tag + 1) as? Button)?.roundButton()
    }

    // MARK: - QuestionnaireExitElement

    var isExitElement: Bool = false

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions + QuestionnaireElementHasButtons

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var view: UIView = {
        UIView(frame: .zero)
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

    internal func initiateView() {
        self.addElementViews()
        self.decorateView()
    }

    internal func decorateView() {
        if self.subviews.count > 0 {
            self.layoutElementViews()
        }
    }
}

/// Subviews assets override
extension Button {
    fileprivate func overrideQuestionnaireAsset(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.titleLabel?.font = .ninchat

        self.setBackgroundImage((delegate?.override(questionnaireAsset: .radioSecondaryBackground) ?? .white).toImage, for: .normal)
        self.setTitleColor(delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorRadioUnselectedText) ?? .QGrayButton, for: .normal)

        self.setBackgroundImage((delegate?.override(questionnaireAsset: .radioPrimaryBackground) ?? .white).toImage, for: .selected)
        self.setTitleColor(delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorRadioSelectedText) ?? .QBlueButtonNormal, for: .selected)

        self.roundButton()
    }
}

extension QuestionnaireElementRadio {
    func shapeRadioView(_ configuration: QuestionnaireConfiguration?) {
        var upperView: UIView?
        configuration?.options?.forEach { [weak self] option in
            guard let button = self?.generateButton(for: option, tag: (configuration?.options?.firstIndex(of: option))!) else { return }
            self?.layoutButton(button, upperView: &upperView)
        }
        view.height?.constant += 8
    }

    internal func generateButton(for option: ElementOption, tag: Int) -> Button {
        let view = Button(frame: .zero) { [weak self, option] button in
            guard let `self` = self else { return }

            self.applySelection(to: button)
            button.isSelected ? self.onElementOptionSelected?(self, option) : self.onElementOptionDeselected?(self, option)
        }

        view.tag = tag + 1
        view.setTitle(option.label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(option.label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        view.setBackgroundImage(UIColor.QBlueButtonHighlighted.toImage, for: .highlighted)
        view.updateTitleScale()

        return view
    }

    internal func layoutButton(_ button: Button, upperView: inout UIView?) {
        defer { upperView = button }
        self.view.addSubview(button)

        if self.scaleToParent {
            button.fix(leading: (0.0, self.view), trailing: (0.0, self.view))
            button.leading?.priority = .almostRequired
            button.trailing?.priority = .almostRequired
        } else if self.width?.constant ?? 0 < self.intrinsicContentSize.width + 32.0 {
            button.fix(width: button.intrinsicContentSize.width + 32.0)
        }
        button
            .fix(top: (8.0, upperView ?? self.view), isRelative: (upperView != nil))
            .fix(height: max(45.0, button.intrinsicContentSize.height + 16.0))
            .center(toX: self.view)
            .roundButton()

        if self.view.height == nil {
            self.view.fix(height: 0)
        }
        view.height?.constant += button.height!.constant + 8
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

/// QuestionnaireElement
extension QuestionnaireElement where Self:QuestionnaireElementRadio {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        if self.didShapedView { return }

        self.elementConfiguration = configuration
        self.shapeTitle(configuration)
        self.shapeRadioView(configuration)
        self.adjustConstraints()
    }
}
