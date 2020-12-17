//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementCheckbox: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireOptionSelectableElement {

    private var iconBorderNormalColor: UIColor! = .QGrayButton
    private var iconBorderSelectedColor: UIColor! = .QBlueButtonNormal

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
    var elementHeight: CGFloat {
        self.title.frame.origin.y + self.title.intrinsicContentSize.height + CGFloat(self.view.height?.constant ?? 0) + self.padding
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideTitle(delegate: delegate)
        self.view.subviews.compactMap({ $0 as? Button }).forEach({ $0.overrideQuestionnaireAsset(with: delegate, isPrimary: $0.isSelected) })
        self.viewWithTag(100)?.subviews.compactMap({ $0 as? UIImageView }).forEach({ $0.tint = delegate?.override(questionnaireAsset: .checkboxSelectedIndicator) ?? UIColor.QBlueButtonHighlighted })

        self.iconBorderNormalColor = delegate?.override(questionnaireAsset: .checkboxDeselectedIndicator) ?? UIColor.QGrayButton
        self.iconBorderSelectedColor = delegate?.override(questionnaireAsset: .checkboxSelectedIndicator) ?? UIColor.QBlueButtonNormal
        self.view.subviews.filter({ !($0 is Button) }).forEach({ $0.round(radius: 23.0 / 2, borderWidth: 2.0, borderColor: self.iconBorderNormalColor) })
    }

    // MARK: - QuestionnaireSettable

    func updateSetAnswers(_ answer: AnyHashable?, state: QuestionnaireSettableState) {
        self.view.subviews.compactMap({ $0 as? Button }).first?.isSelected = answer as? Bool ?? false
        self.viewWithTag(100)?.subviews.compactMap({ $0 as? UIImageView }).first?.isHighlighted = answer as? Bool ?? false
    }

    // MARK: - QuestionnaireOptionSelectableElement

    var onElementOptionSelected: ((ElementOption) -> ())?
    var onElementOptionDeselected: ((ElementOption) -> ())?

    private func select(option: ElementOption) {
        self.view.subviews.compactMap({ $0 as? Button }).first?.isSelected = true
        self.viewWithTag(100)?.subviews.compactMap({ $0 as? UIImageView }).first?.isHighlighted = true
    }

    func deselect(option: ElementOption) {
        self.view.subviews.compactMap({ $0 as? Button }).first?.isSelected = false
        self.viewWithTag(100)?.subviews.compactMap({ $0 as? UIImageView }).first?.isHighlighted = false
    }

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

    private func initiateView() {
        self.addElementViews()
    }

    private func decorateView() {
        if self.view.subviews.count > 0 {
            self.layoutElementViews()
        }
    }
}

/// Subviews assets override
extension Button {
    fileprivate func overrideQuestionnaireAsset(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.titleLabel?.font = .ninchat
        self.setTitleColor(delegate?.override(questionnaireAsset: .checkboxSecondaryText) ?? UIColor.QGrayButton, for: .normal)
        self.setTitleColor(delegate?.override(questionnaireAsset: .checkboxPrimaryText) ?? UIColor.QBlueButtonNormal, for: .selected)
    }
}

/// QuestionnaireElement
extension QuestionnaireElement where Self:QuestionnaireElementCheckbox {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        if self.didShapedView { return }

        self.elementConfiguration = configuration
        self.shapeTitle(configuration)
        self.shapeCheckbox(configuration)
    }
}

extension QuestionnaireElementCheckbox {
    func shapeCheckbox(_ configuration: QuestionnaireConfiguration?) {
        var upperView: UIView?

        let icon = self.generateIcon()
        let button = self.generateButton(label: configuration?.label ?? "", icon: icon)
        self.layout(icon: icon.1, within: icon.0)
        self.layout(button: button, icon: icon.0, upperView: &upperView)
    }

    private func generateButton(label: String, icon: (UIView, UIImageView)) -> Button {
        let view = Button(frame: .zero) { [weak self] button in
            button.isSelected = !button.isSelected

            let option = ElementOption(label: label, value: button.isSelected)
            button.isSelected ? self?.select(option: option) : self?.deselect(option: option)
            button.isSelected ? self?.onElementOptionSelected?(option) : self?.onElementOptionDeselected?(option)
        }

        view.setTitle(label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        view.titleLabel?.font = .ninchat
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.textAlignment = .left
        view.titleLabel?.lineBreakMode = .byWordWrapping

        return view
    }

    private func generateIcon() -> (UIView, UIImageView) {
        let imgViewContainer = UIView(frame: .zero)
        imgViewContainer.backgroundColor = .clear
        imgViewContainer.isUserInteractionEnabled = false
        imgViewContainer.isExclusiveTouch = false
        imgViewContainer.tag = 100

        return (imgViewContainer, UIImageView(image: nil, highlightedImage: UIImage(named: "icon_checkbox_selected", in: .SDKBundle, compatibleWith: nil)))
    }

    private func layout(icon: UIImageView, within view: UIView) {
        view.addSubview(icon)

        icon
            .fix(top: (5.0, view), bottom: (5.0, view))
            .fix(leading: (5.0, view), trailing: (5.0, view))
    }

    private func layout(button: Button, icon: UIView, upperView: inout UIView?) {
        self.view.addSubview(button)
        self.view.addSubview(icon)

        /// Layout icon
        icon
            .fix(leading: (0.0, self.view))
            .fix(width: 23.0, height: 23.0)
            .center(toY: button)
        icon.leading?.priority = .almostRequired
        icon.width?.priority = .almostRequired
        icon.height?.priority = .almostRequired

        /// Layout button
        if let upperView = upperView {
            button.fix(top: (2.0, upperView), isRelative: true)
        } else {
            button.fix(top: (0.0, self.view), isRelative: false)
        }
        button
            .fix(trailing: (8.0, self.view), relation: .greaterThan)
            .fix(leading: (0.0, icon), isRelative: true)
            .fix(width: button.intrinsicContentSize.width + 32.0)
            .fix(height: max(32.0, button.intrinsicContentSize.height))
        button.leading?.priority = .required

        /// Layout parent view
        if let height = self.view.height {
            height.constant += button.height?.constant ?? 0
        } else {
            self.view.fix(height: (button.height?.constant ?? 0) + 16.0)
        }

        upperView = button
    }
}
