//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementCheckbox: UIView, QuestionnaireElement, QuestionnaireSettable, QuestionnaireOptionSelectableElement, QuestionnaireElementHasDefaultAnswer, HasOptions {

    private var iconBorderNormalColor: UIColor! = .QGrayButton
    private var iconBorderSelectedColor: UIColor! = .QBlueButtonNormal
    private(set) var subElements: [Int:QuestionnaireElement] = [:]
    private var upperView: UIView?

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
        get {
            let viewHeight = CGFloat(self.view.height!.constant) + 16.0
            if self.subElements.count == 0, index == 0 {
                self.view.subviews.first(where: { $0 is NINButton })?.center(toY: self)
            }
            return viewHeight
        }
        set {}
    }

    // MARK: - QuestionnaireElementHasDefaultAnswer

    var didSubmitDefaultAnswer: Bool = false
    var defaultAnswer: Array<(QuestionnaireElement,ElementOption)>? {
        guard !didSubmitDefaultAnswer else { return nil }
        defer { didSubmitDefaultAnswer = true }

        return self.subElements.values.reduce(into: []) { (answers: inout Array<(QuestionnaireElement,ElementOption)>, element: QuestionnaireElement) in
            answers.append((element, ElementOption(label: element.elementConfiguration?.label ?? "", value: false)))
        }
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.view.subviews.compactMap({ $0 as? NINButton }).forEach({ button in
            if let selectedTextColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorCheckboxUnselectedText) {
                button.setTitleColor(selectedTextColor, for: .normal)
            } else {
                button.setTitleColor(.black, for: .normal)
            }
            if let selectedTextColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorCheckboxSelectedText) {
                button.setTitleColor(selectedTextColor, for: .selected)
            } else {
                button.setTitleColor(.QBlueButtonNormal, for: .selected)
            }
        })
        self.view.allSubviews.filter({ $0.tag >= 200 }).compactMap({ $0 as? UIImageView }).forEach({ imageView in
            if let tintColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireCheckboxSelectedIndicator) {
                imageView.tint = tintColor
            } else {
                imageView.tint = .QBlueButtonHighlighted
            }
        })

        self.view.subviews.filter({ !($0 is NINButton) }).forEach({ view in
            if let layer = delegate?.override(layerAsset: .ninchatQuestionnaireCheckbox) {
                view.layer.apply(layer)
            } else {
                view
                    .round(radius: 23.0 / 2, borderWidth: 2.0, borderColor: self.iconBorderNormalColor)
                    .backgroundColor = .white
            }
        })
    }

    // MARK: - QuestionnaireSettable

    func updateSetAnswers(_ answer: AnyHashable?, configuration: QuestionnaireConfiguration?, state: QuestionnaireSettableState) {
        if let checkbox = self.view.subviews
            .compactMap({ $0 as? NINButton })
            .first(where: { $0.titleLabel?.text == configuration?.label }) {
            
            checkbox.isSelected = answer as? Bool ?? false
            
            self.view.allSubviews
                .filter({ $0.tag == 100+checkbox.tag })
                .compactMap({ $0 as? UIImageView })
                .first?.isHighlighted = answer as? Bool ?? false
        }
    }

    // MARK: - QuestionnaireOptionSelectableElement

    var onElementOptionSelected: ((QuestionnaireElement, ElementOption) -> ())?
    var onElementOptionDeselected: ((QuestionnaireElement, ElementOption) -> ())?

    private func select(option: ElementOption) {
        if let checkbox = self.view.subviews.compactMap({ $0 as? NINButton }).first(where: { $0.title(for: .normal) == option.label }) {
            checkbox.isSelected = true
            self.view.allSubviews.filter({ $0.tag == 100+checkbox.tag }).compactMap({ $0 as? UIImageView }).first?.isHighlighted = true
            self.view.allSubviews.filter({ $0.tag == 200+checkbox.tag }).forEach({ $0.layer.borderColor = self.iconBorderSelectedColor.cgColor })
        }
    }

    func deselect(option: ElementOption) {
        if let checkbox = self.view.subviews.compactMap({ $0 as? NINButton }).first(where: { $0.title(for: .normal) == option.label }) {
            checkbox.isSelected = false
            self.view.allSubviews.filter({ $0.tag == 100+checkbox.tag }).compactMap({ $0 as? UIImageView }).first?.isHighlighted = false
            self.view.allSubviews.filter({ $0.tag == 200+checkbox.tag }).forEach({ $0.layer.borderColor = self.iconBorderNormalColor.cgColor })
        }
    }

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions + QuestionnaireElementHasButtons

    private(set) lazy var view: UIView = {
        UIView(frame: .zero)
    }()
    
    // MARK: - HasOptions
    
    var optionsView: UIView {
        self.view
    }
    
    // MARK: - UIView life-cycle

    override var isUserInteractionEnabled: Bool {
        didSet {
            self.view.subviews.forEach({ v in
                if let button = v as? NINButton {
                    button.isEnabled = isUserInteractionEnabled
                } else if v.tag >= 200 {
                    v.isUserInteractionEnabled = isUserInteractionEnabled
                }
            })
        }
    }
    
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
        self.addSubview(view)
        self.decorateView()
    }

    private func decorateView() {
        if self.subviews.count > 0 {
            view
                .fix(leading: (8.0, self), trailing: (8.0, self))
                .fix(top: (8.0, self), bottom: (0.0, self), isRelative: false)
                .fix(width: self.bounds.width)
                .center(toX: self)
            view.leading?.priority = .almostRequired
            view.trailing?.priority = .almostRequired
        }
    }
}

/// Subviews assets override
extension NINButton {
    fileprivate func overrideQuestionnaireAsset(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.titleLabel?.font = .ninchat
        self.setTitleColor(delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorCheckboxUnselectedText) ?? .black, for: .normal)
        self.setTitleColor(delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorCheckboxSelectedText) ?? .QBlueButtonNormal, for: .selected)
    }
}

/// QuestionnaireElement and SubElements
extension QuestionnaireElementCheckbox {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        elementConfiguration = configuration
        shapeCheckbox(configuration)
    }

    func appendView(_ element: QuestionnaireElement, configuration: QuestionnaireConfiguration?) {
        if subElements.count == 0 {
            /// Since the following line copies a reference of `self`,
            /// the first element of the array contains all subviews
            /// With that in mind, it is possible to use the array to find the target element
            /// in the function `updateSetAnswers(_:state)`
            subElements[index] = self
        }

        index += 1
        subElements[index] = element
        shapeCheckbox(configuration?.elements![index])
    }
}

// MARK: - Element Shape
extension QuestionnaireElementCheckbox {
    func shapeCheckbox(_ configuration: QuestionnaireConfiguration?) {
        let icon = self.generateIcon()
        let button = self.generateButton(label: configuration?.label ?? "", icon: icon)
        self.layout(icon: icon.1, within: icon.0)
        self.layout(button: button, icon: icon.0)
    }

    private func generateButton(label: String, icon: (UIView, UIImageView)) -> NINButton {
        let view = NINButton(frame: .zero) { [weak self] button in
            button.isSelected = !button.isSelected
            guard let `self` = self else { return }
            let element = self.subElements[button.tag - 100] ?? self

            let option = ElementOption(label: label, value: button.isSelected)
            button.isSelected ? self.select(option: option) : self.deselect(option: option)
            self.onElementOptionSelected?(element, option)
        }

        view.tag = 100 + index
        view.setTitle(label, for: .normal)
        view.setTitleColor(.black, for: .normal)
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
        imgViewContainer.isExclusiveTouch = false
        imgViewContainer.isUserInteractionEnabled = true
        imgViewContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onIconTapped(_:))))
        imgViewContainer.tag = 300 + index

        let imageView = UIImageView(image: nil, highlightedImage: UIImage(named: "icon_checkbox_selected", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate))
        imageView.tag = 200 + index

        return (imgViewContainer, imageView)
    }

    private func layout(icon: UIImageView, within view: UIView) {
        view.addSubview(icon)

        icon
            .fix(top: (5.0, view), bottom: (5.0, view))
            .fix(leading: (5.0, view), trailing: (5.0, view))
    }

    private func layout(button: NINButton, icon: UIView) {
        defer { upperView = button }
        self.view.addSubview(button)
        self.view.addSubview(icon)

        /// Layout icon
        icon
            .fix(leading: (8.0, self.view))
            .fix(width: 23.0, height: 23.0)
            .center(toY: button)
        icon.leading?.priority = .almostRequired
        icon.width?.priority = .almostRequired
        icon.height?.priority = .almostRequired

        /// Layout button
        button
            .fix(top: (4.0, upperView ?? self.view), isRelative: upperView != nil)
            .fix(trailing: (8.0, self.view), relation: .greaterThan)
            .fix(leading: (0.0, icon), isRelative: true)
            .fix(width: button.intrinsicContentSize.width + 32.0)
            .fix(height: max(32.0, button.intrinsicContentSize.height))

        /// Layout parent view
        if self.view.height == nil {
            self.view.fix(height: 0)
        }
        view.height?.constant += button.height!.constant + 4
    }
}

// MARK: - Icon tap gestures
extension QuestionnaireElementCheckbox {
    @objc
    private func onIconTapped(_ gesture: UITapGestureRecognizer) {
        guard let imgView = gesture.view?.subviews.first(where: { $0.tag >= 200 }) as? UIImageView, let button = self.view.viewWithTag(imgView.tag - 100) as? NINButton else { return }
        button.closure?(button)
    }
}
