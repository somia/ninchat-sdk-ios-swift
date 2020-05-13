//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementSelectButton: UIButton, QuestionnaireElement {

    // MARK: - QuestionnaireElement

    var configuration: ElementQuestionnaire? {
        didSet {
            self.shapeView()
        }
    }
    var onElementFocused: ((QuestionnaireElement) -> ())?

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        if let overrideImage = delegate?.override(imageAsset: isPrimary ? .primaryButton : .secondaryButton) {
            self.setBackgroundImage(overrideImage, for: .normal)
            self.layer.borderWidth = 0
        }
        if let overrideColor = delegate?.override(colorAsset: isPrimary ? .buttonPrimaryText : .buttonSecondaryText) {
            self.setTitleColor(overrideColor, for: .normal)
        }
    }

    // MARK: - UIView life-cycle

    override var isEnabled: Bool {
        didSet {
            self.alpha = isEnabled ? 1.0 : 0.5
        }
    }
    override var isSelected: Bool {
        didSet {
            self.shapeView()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.tag = -1

        guard self.buttonType == .custom else { fatalError("Element select button should be of type `Custom`") }
        self.addTarget(self, action: #selector(self.onButtonTapped(_:)), for: .touchUpInside)
    }

    // MARK: - User actions

    @objc
    private func onButtonTapped(_ sender: QuestionnaireElementSelectButton) {
        self.isSelected = !self.isSelected
        self.onElementFocused?(sender)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementSelectButton {
    func shapeView() {
        self.backgroundColor = .clear
        self.titleLabel?.font = .ninchat
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.textAlignment = .center
        self.titleLabel?.lineBreakMode = .byWordWrapping

        self.setTitle(configuration?.label, for: .normal)
        self.setTitleColor(.QGrayButton, for: .normal)
        self.setTitle(configuration?.label, for: .selected)
        self.setTitleColor(.QBlueButtonNormal, for: .selected)

        self
                .fix(width: self.intrinsicContentSize.width + 32.0, height: max(45.0, self.intrinsicContentSize.height + 16.0))
                .round(radius: 15.0, borderWidth: 1.0, borderColor: self.isSelected ? .QBlueButtonNormal : .QGrayButton)
    }
}