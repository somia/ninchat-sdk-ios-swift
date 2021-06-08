//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class NINButton: UIButton, HasCustomLayer {
    var closure: ((NINButton) -> Void)?
    var type: QuestionnaireButtonType?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(touchUpInside(sender:)), for: .touchUpInside)
    }
    
    convenience init(frame: CGRect, touch closure: ((UIButton) -> Void)?) {
        self.init(frame: frame)
        self.closure = closure
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyLayerOverride(view: self)
    }

    // MARK: - User actions
    
    override func sendActions(for controlEvents: UIControl.Event) {
        super.sendActions(for: controlEvents)
        self.closure?(self)
    }
    
    @objc
    internal func touchUpInside(sender: UIButton) {
        self.closure?(self)
    }
    
    // MARK: - Helper methods
    
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary primary: Bool) {
        self.titleLabel?.font = .ninchat
        self.backgroundColor = .clear

        if let layer = delegate?.override(layerAsset: primary ? .ninchatPrimaryButton : .ninchatSecondaryButton) {
            self.layer.insertSublayer(layer, below: self.titleLabel?.layer)
        }
        /// TODO: REMOVE legacy delegate
        else if let overrideImage = delegate?.override(imageAsset: primary ? .primaryButton : .secondaryButton) {
            self.setBackgroundImage(overrideImage, for: .normal)
            self.roundButton()
        } else {
            self.setTitleColor(primary ? .white : .defaultBackgroundButton, for: .normal)
            self.backgroundColor = primary ? .defaultBackgroundButton : .white
            self.roundButton()
        }
        if let overrideColor = delegate?.override(colorAsset: primary ? .ninchatColorButtonPrimaryText : .ninchatColorButtonSecondaryText) {
            self.setTitleColor(overrideColor, for: .normal)
        }
    }
}

/// Helper for questionnaire items

extension NINButton {
    func roundButton() {
        self.round(borderWidth: 1.0, borderColor: (self.isSelected ? self.titleColor(for: .selected) : self.titleColor(for: .normal)) ?? .QGrayButton)
    }
}
