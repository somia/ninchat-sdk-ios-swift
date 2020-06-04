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
    var scaleToParent: Bool = false
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
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0)
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.overrideTitle(delegate: delegate)
        self.view.subviews.compactMap({ $0 as? Button }).forEach({ $0.overrideQuestionnaireAsset(with: delegate, isPrimary: $0.isSelected) })
        self.view.allSubviews.filter({ $0 is UIImageView }).forEach({ $0.tintColor = delegate?.override(questionnaireAsset: .checkboxSelectedIndicator) ?? UIColor.QBlueButtonHighlighted })

        self.iconBorderNormalColor = delegate?.override(questionnaireAsset: .checkboxDeselectedIndicator) ?? UIColor.QGrayButton
        self.iconBorderSelectedColor = delegate?.override(questionnaireAsset: .checkboxSelectedIndicator) ?? UIColor.QBlueButtonNormal
        self.view.subviews.filter({ ($0 is UIView) && !($0 is Button) }).forEach({ $0.round(radius: 23.0 / 2, borderWidth: 2.0, borderColor: self.iconBorderNormalColor) })
    }

    // MARK: - QuestionnaireSettable

    var presetAnswer: AnyHashable? {
        didSet {
            if let answer = self.presetAnswer as? String,
               let option = self.elementConfiguration?.options?.first(where: { $0.label == answer }),
               let button = self.view.subviews.compactMap({ $0 as? Button }).first(where: { $0.titleLabel?.text == option.label }) {
                button.closure?(button)
            }
        }
    }

    // MARK: - QuestionnaireOptionSelectableElement

    var onElementOptionSelected: ((ElementOption) -> ())?
    var onElementOptionDeselected: ((ElementOption) -> ())?

    func deselect(option: ElementOption) {
        guard let tag = self.elementConfiguration?.options?.firstIndex(where: { $0.label == option.label }) else { return }
        (self.view.viewWithTag(tag + 100) as? Button)?.isSelected = false
        (self.view.viewWithTag(tag + 200) as? UIImageView)?.isHighlighted = false
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
        self.elementConfiguration = configuration

        self.shapeTitle(configuration)
        guard self.view.subviews.count == 0 else { return }
        self.shapeCheckbox(configuration)
    }
}

extension QuestionnaireElementCheckbox {
    func shapeCheckbox(_ configuration: QuestionnaireConfiguration?) {
        var upperView: UIView?
        configuration?.options?.forEach { [unowned self] option in
            let icon = self.generateIcon(tag: (configuration?.options?.firstIndex(of: option))!)
            let button = self.generateButton(for: option, icon: icon, tag: (configuration?.options?.firstIndex(of: option))!)
            self.layout(icon: icon.1, within: icon.0)
            self.layout(button: button, icon: icon.0, upperView: &upperView)
        }
    }

    private func generateButton(for option: ElementOption, icon: (UIView, UIImageView), tag: Int) -> Button {
        let view = Button(frame: .zero) { [weak self] button in
            button.isSelected = !button.isSelected
            icon.0.round(radius: 23.0 / 2, borderWidth: 2.0, borderColor: (button.isSelected ? self?.iconBorderSelectedColor : self?.iconBorderNormalColor) ?? .QGrayButton)
            icon.1.isHighlighted = button.isSelected
            button.isSelected ? self?.onElementOptionSelected?(option) : self?.onElementOptionDeselected?(option)
        }

        view.tag = tag + 100
        view.setTitle(option.label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(option.label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        view.titleLabel?.font = .ninchat
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.textAlignment = .left
        view.titleLabel?.lineBreakMode = .byWordWrapping

        return view
    }

    private func generateIcon(tag: Int) -> (UIView, UIImageView) {
        let imgViewContainer = UIView(frame: .zero)
        imgViewContainer.backgroundColor = .clear
        imgViewContainer.isUserInteractionEnabled = false
        imgViewContainer.isExclusiveTouch = false

        let image = UIImageView(image: nil, highlightedImage: UIImage(named: "icon_checkbox_selected", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate))
        image.tag = tag + 200

        return (imgViewContainer, image)
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
        icon.leading?.priority = .required
        icon.width?.priority = .required
        icon.height?.priority = .required

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
