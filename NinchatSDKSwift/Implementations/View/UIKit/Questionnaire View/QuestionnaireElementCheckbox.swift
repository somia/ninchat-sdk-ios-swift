//
// Copyright (c) 13.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementCheckbox: UIButton, QuestionnaireElement {

    // MARK: - QuestionnaireElement

    var configuration: ElementQuestionnaire? {
        didSet {
            self.shapeView()
        }
    }
    var onElementFocused: ((QuestionnaireElement) -> ())?

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {

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

        guard self.buttonType == .custom else { fatalError("Element select button should be of type `Custom`") }
        self.addTarget(self, action: #selector(self.onCheckboxTapped(_:)), for: .touchUpInside)
    }

    // MARK: - User actions

    @objc
    private func onCheckboxTapped(_ sender: QuestionnaireElementSelectButton) {
        self.isSelected = !self.isSelected
        self.onElementFocused?(sender)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementCheckbox {
    func shapeView() {
        self.subviews.filter({ $0.tag == -2 }).forEach({ $0.removeFromSuperview() })

        self.backgroundColor = .clear
        self.titleLabel?.font = .ninchat
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.textAlignment = .left
        self.titleLabel?.lineBreakMode = .byWordWrapping

        guard self.tag != -1 else { fatalError("`Checkbox` types need to have tag as the indicator index") }
        guard let options = self.configuration?.options, options.count > self.tag else { fatalError("There are not any defined options for given index: \(self.tag)") }
        self.setTitle(options[self.tag].label, for: .normal)
        self.setTitleColor(.QGrayButton, for: .normal)
        self.setTitle(options[self.tag].label, for: .selected)
        self.setTitleColor(.QBlueButtonNormal, for: .selected)

        #warning("The image has to be changed")
        let imageViewContainer = UIView(frame: .zero)
        imageViewContainer.backgroundColor = .clear
        imageViewContainer.isUserInteractionEnabled = false
        imageViewContainer.isExclusiveTouch = false
        imageViewContainer.tag = -2

        let icon = UIImageView(image: nil, highlightedImage: UIImage(named: "icon_checkbox_selected", in: .SDKBundle, compatibleWith: nil))
        imageViewContainer.addSubview(icon)
        icon
            .fix(top: (5.0, imageViewContainer), bottom: (5.0, imageViewContainer))
            .fix(leading: (5.0, imageViewContainer), trailing: (5.0, imageViewContainer))

        self.addSubview(imageViewContainer)
        imageViewContainer
                .fix(width: 23.0, height: 23.0)
                .fix(leading: (0, self))
                .center(toY: self)
                .round(borderWidth: 2.0, borderColor: self.isSelected ? .QBlueButtonNormal : .QGrayButton)
        icon.isHighlighted = self.isSelected

        self.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 32.0, bottom: 0.0, right: 0.0)
        self.fix(width: self.intrinsicContentSize.width + 32.0, height: max(30.0, self.intrinsicContentSize.height + 16.0))
    }
}