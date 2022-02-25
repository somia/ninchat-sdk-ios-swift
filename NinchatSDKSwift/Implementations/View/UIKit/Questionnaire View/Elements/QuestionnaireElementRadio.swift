//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireExitElement {
    var isExitElement: Bool { set get }
}

class QuestionnaireElementRadio: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireOptionSelectableElement, QuestionnaireExitElement, HasExternalLink {

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
        self.delegate = delegate
        self.overrideTitle(delegate: delegate)
        self.view.subviews.compactMap({ $0 as? NINButton }).forEach({ $0.overrideQuestionnaireAsset(with: delegate, isPrimary: $0.isSelected) })
    }

    // MARK: - QuestionnaireSettable

    func updateSetAnswers(_ answer: AnyHashable?, configuration: QuestionnaireConfiguration?, state: QuestionnaireSettableState) {
        switch state {
        case .set:
            guard let option = self.elementConfiguration?.options?.first(where: { $0.value == answer }),
                  let button = self.view.subviews.compactMap({ $0 as? NINButton }).first(where: { $0.titleLabel?.text == option.label })
                else { return }
            
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
        if let button = self.view.viewWithTag(tag + 1) as? NINButton {
            button.isSelected = false
            button.roundButton()
        }
    }

    // MARK: - QuestionnaireExitElement

    var isExitElement: Bool = false

    // MARK: - HasExternalLink

    var didTapOnURL: ((URL?) -> ())?

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions + QuestionnaireElementHasButtons

    private weak var delegate: NINChatSessionInternalDelegate?
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
extension NINButton {
    fileprivate func overrideQuestionnaireAsset(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.titleLabel?.font = .ninchat

        if let layer = delegate?.override(layerAsset: (isPrimary) ? .ninchatQuestionnaireRadioSelected : .ninchatQuestionnaireRadioUnselected) {
            self.layer.apply(layer)
        } else {
            self.roundButton()
        }

        self.setTitleColor(delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorRadioUnselectedText) ?? .QGrayButton, for: .normal)
        self.setTitleColor(delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorRadioSelectedText) ?? .QBlueButtonNormal, for: .selected)

        if self.isSelected {
            self.imageView?.tintColor = self.titleColor(for: .selected)
        } else {
            self.imageView?.tintColor = self.titleColor(for: .normal)
        }
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

    internal func generateButton(for option: ElementOption, tag: Int) -> NINButton {
        let view = NINButton(frame: .zero) { [weak self, option] button in
            guard let `self` = self else { return }

            self.applySelection(to: button)
            if button.isSelected {
                self.didTapOnURL?(URL(string: option.href ?? ""))
                self.onElementOptionSelected?(self, option)
            } else {
                self.onElementOptionDeselected?(self, option)
            }
        }

        view.tag = tag + 1
        view.setTitle(option.label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(option.label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        view.setBackgroundImage(UIColor.QBlueButtonHighlighted.toImage, for: .highlighted)
        if option.href != nil {
            view.setImage(UIImage(named: "icon-external-link", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
            view.imageView?.tintColor = view.titleColor(for: .normal)
            view.semanticContentAttribute = .forceRightToLeft
            view.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 0.0)
        } else {
            view.setImage(nil, for: .normal)
            view.imageEdgeInsets = .zero
            view.semanticContentAttribute = .unspecified
        }
        view.updateTitleScale()

        return view
    }

    internal func layoutButton(_ button: NINButton, upperView: inout UIView?) {
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

        if self.view.height == nil {
            self.view.fix(height: 0)
        }
        view.height?.constant += button.height!.constant + 8
    }

    private func applySelection(to button: UIButton) {
        self.view.subviews.forEach({ btn in
            guard let button = btn as? NINButton else { return }

            button.isSelected = false
            button.overrideQuestionnaireAsset(with: self.delegate, isPrimary: button.isSelected)
        })

        button.isSelected = true
        (button as! NINButton).overrideQuestionnaireAsset(with: self.delegate, isPrimary: button.isSelected)
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
