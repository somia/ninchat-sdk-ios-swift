//
// Copyright (c) 21.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable

final class QuestionnaireNavigationCell: UITableViewCell, HasCustomLayer, QuestionnaireNavigationButtons {

    // MARK: - QuestionnaireElementWithNavigationButtons

    var shouldShowNextButton: Bool! = false
    var shouldShowBackButton: Bool! = false
    var isLastItemInTable: Bool! = true
    var configuration: QuestionnaireConfiguration? {
        didSet {
            self.buttons.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            self.shapeNavigationButtons(configuration)
            self.decorateView()
        }
    }

    var requirementSatisfactionUpdater: ((Bool) -> Void)?
    var onNextButtonTapped: (() -> Void)?
    var onBackButtonTapped: (() -> Void)?

    private(set) lazy var buttons: UIStackView = {
        let view = UIStackView(frame: .zero)
        view.spacing = 8.0

        return view
    }()
    private(set) lazy var separator: UIView = {
        UIView(frame: .zero)
    }()

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        if let nextButton = self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).first(where: { $0.type == .next }) {
            applyLayerOverride(view: nextButton)
        }
        if let backButton = self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).first(where: { $0.type == .back }) {
            applyLayerOverride(view: backButton)
        }
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        if let nextButton = self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).first(where: { $0.type == .next }) {
            let textColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorNavigationNextText) ?? .white
            
            nextButton.imageView?.tint = textColor
            nextButton.imageView?.tintColor = textColor
            nextButton.tintColor = textColor
            nextButton.setTitleColor(textColor, for: .normal)
            nextButton.setTitleColor(textColor, for: .selected)

            if let layer = delegate?.override(layerAsset: .ninchatQuestionnaireNavigationNext) {
                nextButton.layer.insertSublayer(layer, at: 0)
            } else {
                nextButton.layer.borderColor = UIColor.QBlueButtonNormal.cgColor
                nextButton.backgroundColor = .QBlueButtonNormal
                nextButton.round(radius: 45.0 / 2, borderWidth: 1.0, borderColor: .QBlueButtonNormal)
            }
        }
        if let backButton = self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).first(where: { $0.type == .back }) {
            let textColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorNavigationBackText) ?? .QBlueButtonNormal
            
            backButton.imageView?.tint = textColor
            backButton.imageView?.tintColor = textColor
            backButton.tintColor = textColor
            backButton.setTitleColor(textColor, for: .normal)
            backButton.setTitleColor(textColor, for: .selected)

            if let layer = delegate?.override(layerAsset: .ninchatQuestionnaireNavigationBack) {
                backButton.layer.insertSublayer(layer, at: 0)
            } else {
                backButton.layer.borderColor = UIColor.QBlueButtonNormal.cgColor
                backButton.backgroundColor = .white
                backButton.round(radius: 45.0 / 2, borderWidth: 1.0, borderColor: .QBlueButtonNormal)
            }
        }
    }

    func setSatisfaction(_ satisfied: Bool) {
        debugger("Set navigation Satisfaction: \(satisfied && self.isLastItemInTable)")
        self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).first(where: { $0.type == .next })?.isEnabled = satisfied && self.isLastItemInTable
        /// back button should not get disabled according to user inputs
        /// it is always enabled for the last item
        self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).first(where: { $0.type == .back })?.isEnabled = self.isLastItemInTable
        self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).forEach({ $0.alpha = $0.isEnabled ? 1.0 : 0.5 })
    }

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        self.initiateView()
    }

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
        self.addNavigationButtons()
    }

    private func decorateView() {
        if self.buttons.arrangedSubviews.count > 0 {
            self.layoutNavigationButtons()
        }
        self.requirementSatisfactionUpdater = { [weak self] satisfied in
            self?.setSatisfaction(satisfied)
        }
    }
}

extension QuestionnaireNavigationCell {
    func addNavigationButtons() {
        /// Must be called in `view.awakeFromNib()` function
        self.contentView.addSubview(buttons)
    }

    func layoutNavigationButtons() {
        buttons
            .fix(leading: (15.0, self.contentView), trailing: (15.0, self.contentView))
            .fix(height: 45.0)
            .center(toY: self.contentView)
        buttons.leading?.priority = .almostRequired
        buttons.trailing?.priority = .almostRequired
    }

    func shapeNavigationButtons(_ configuration: QuestionnaireConfiguration?) {
        func drawBackButton(isVisible: Bool) {
            if self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).filter({ $0.type == .back }).count > 0 || !isVisible {
                return
            }

            let button = NINButton(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onBackButtonTapped?()
            }
            button.type = .back
            button.isHidden = !isVisible
            button.isEnabled = isVisible
            self.layoutButton(button, configuration: configuration?.buttons, type: .back)
        }
        func drawNextButton(isVisible: Bool) {
            if self.buttons.arrangedSubviews.compactMap({ $0 as? NINButton }).filter({ $0.type == .next }).count > 0 || !isVisible {
                return
            }

            let button = NINButton(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onNextButtonTapped?()
            }
            button.type = .next
            button.isHidden = !isVisible
            button.isEnabled = isVisible
            self.layoutButton(button, configuration: configuration?.buttons, type: .next)
        }

        /// According to `https://github.com/somia/mobile/issues/238`
        /// " Basically you have buttons always displayed unless they are removed in config. "
        /// " But it should omit 'back' for the first element "
        drawBackButton(isVisible: self.shouldShowBackButton)
        addSeparator(isVisible: self.shouldShowNextButton || self.shouldShowBackButton)
        drawNextButton(isVisible: self.shouldShowNextButton)
    }

    private func layoutButton(_ button: UIButton, configuration: ButtonQuestionnaire?, type: QuestionnaireButtonType) {
        self.buttons.insertArrangedSubview(button, at: self.buttons.arrangedSubviews.count)
        if type == .back {
            self.shapeNavigationBack(button: button, configuration: configuration?.back)
        } else if type == .next {
            self.shapeNavigationNext(button: button, configuration: configuration?.next)
        }

        button.titleLabel?.font = .ninchat
        button.imageEdgeInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        button.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button
            .fix(width: button.intrinsicContentSize.width + 32.0, height: 45.0)
            .width?.priority = .almostRequired
    }

    private func addSeparator(isVisible: Bool) {
        guard isVisible, self.buttons.arrangedSubviews.filter({ !($0 is NINButton) }).count == 0 else { return }
        self.buttons.addArrangedSubview(self.separator)
    }

    private func shapeNavigationNext(button: UIButton, configuration: AnyCodable?) {
        if let title = configuration?.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.white, for: .selected)
        } else {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        }
    }

    private func shapeNavigationBack(button: UIButton, configuration: AnyCodable?) {
        if let title = configuration?.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.QBlueButtonNormal, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.QBlueButtonHighlighted, for: .selected)
        } else {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .selected)
        }
    }
}
