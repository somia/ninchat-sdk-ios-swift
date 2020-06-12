//
// Copyright (c) 21.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable

final class QuestionnaireNavigationCell: UITableViewCell, QuestionnaireNavigationButtons {

    // MARK: - QuestionnaireElementWithNavigationButtons

    var configuration: QuestionnaireConfiguration? {
        didSet {
            self.shapeNavigationButtons(configuration)
            self.decorateView()
        }
    }
    var requirementsSatisfied: Bool = true {
        didSet {
            self.setSatisfaction(requirementsSatisfied)
        }
    }

    var requirementSatisfactionUpdater: ((Bool) -> Void)?
    var onNextButtonTapped: (() -> Void)?
    var onBackButtonTapped: (() -> Void)?

    private(set) lazy var buttons: UIView = {
        UIView(frame: .zero)
    }()

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        if let nextButton = self.buttons.subviews.first(where: { $0.trailing != nil }) as? Button {
            if nextButton.titleLabel?.text?.isEmpty ?? true {
                nextButton.imageView?.tint = delegate?.override(questionnaireAsset: .navigationNextText) ?? .white
            } else {
                nextButton.setTitleColor(delegate?.override(questionnaireAsset: .navigationNextText) ?? .white, for: .normal)
                nextButton.setTitleColor(delegate?.override(questionnaireAsset: .navigationNextText) ?? .white, for: .selected)
            }
            nextButton.layer.borderColor = delegate?.override(questionnaireAsset: .navigationNextText)?.cgColor ?? UIColor.QBlueButtonNormal.cgColor
            nextButton.backgroundColor = delegate?.override(questionnaireAsset: .navigationNextBackground) ?? .QBlueButtonNormal
        }
        if let backButton = self.buttons.subviews.first(where: { $0.leading != nil }) as? Button {
            if backButton.titleLabel?.text?.isEmpty ?? true {
                backButton.imageView?.tint = delegate?.override(questionnaireAsset: .navigationBackText) ?? .QBlueButtonNormal
            } else {
                backButton.setTitleColor(delegate?.override(questionnaireAsset: .navigationBackText) ?? .QBlueButtonNormal, for: .normal)
                backButton.setTitleColor(delegate?.override(questionnaireAsset: .navigationBackText) ?? .QBlueButtonNormal, for: .selected)
            }
            backButton.layer.borderColor = delegate?.override(questionnaireAsset: .navigationBackText)?.cgColor ?? UIColor.QBlueButtonNormal.cgColor
            backButton.backgroundColor = delegate?.override(questionnaireAsset: .navigationBackBackground) ?? .white
        }
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
        if self.buttons.subviews.count > 0 {
            self.layoutNavigationButtons()
        }
        self.requirementSatisfactionUpdater = { [weak self] satisfied in
            self?.setSatisfaction(satisfied)
        }
    }

    private func setSatisfaction(_ satisfied: Bool) {
        if let nextButton = self.buttons.subviews.compactMap({ $0 as? UIButton }).first(where: { $0.trailing != nil }) {
            nextButton.isEnabled = satisfied
            nextButton.alpha = (satisfied) ? 1.0 : 0.5
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
            .fix(leading: (8.0, self.contentView), trailing: (8.0, self.contentView))
            .fix(height: 45.0)
            .center(toY: self.contentView)
    }

    func shapeNavigationButtons(_ configuration: QuestionnaireConfiguration?) {
        func drawBackButton() {
            let button = Button(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onBackButtonTapped?()
            }
            self.layoutButton(button, configuration: configuration?.buttons, type: .back)
        }
        func drawNextButton() {
            let button = Button(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onNextButtonTapped?()
            }
            self.layoutButton(button, configuration: configuration?.buttons, type: .next)
        }

        /// According to `https://github.com/somia/mobile/issues/238`
        /// " Basically you have buttons always displayed unless they are removed in config. "
        if configuration?.buttons == nil {
            drawBackButton()
            drawNextButton()
        } else if let configuration = configuration?.buttons, configuration.hasValidButtons {
            if configuration.hasValidBackButton { drawBackButton() }
            if configuration.hasValidNextButton { drawNextButton() }
        }
    }

    private func layoutButton(_ button: UIButton, configuration: ButtonQuestionnaire?, type: QuestionnaireButtonType) {
        self.buttons.addSubview(button)

        button.titleLabel?.font = .ninchat
        button.imageEdgeInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        button
            .fix(width: max(80.0, self.intrinsicContentSize.width + 32.0), height: 45.0)
            .round(radius: 45.0 / 2, borderWidth: 1.0, borderColor: .QBlueButtonNormal)
        if type == .back {
            self.shapeNavigationBack(button: button, configuration: configuration?.back)
        } else if type == .next {
            self.shapeNavigationNext(button: button, configuration: configuration?.next)
        }
    }

    private func shapeNavigationNext(button: UIButton, configuration: AnyCodable?) {
        if let title = configuration?.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.white, for: .selected)
        } else {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .highlighted)
        }

        button
            .fix(trailing: (16.0, self.buttons))
            .center(toY: self.buttons)
    }

    private func shapeNavigationBack(button: UIButton, configuration: AnyCodable?) {
        if let title = configuration?.value as? String {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.QBlueButtonNormal, for: .normal)
            button.setTitle(title, for: .selected)
            button.setTitleColor(.QBlueButtonHighlighted, for: .selected)
        } else {
            button.setTitle("", for: .normal)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .normal)
            button.setTitle("", for: .selected)
            button.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .selected)
        }
        button
            .fix(leading: (16.0, self.buttons))
            .center(toY: self.buttons)
    }
}
