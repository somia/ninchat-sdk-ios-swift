//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class Button: UIButton {
    var closure: ((Button) -> Void)?
    
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
        if let overrideImage = delegate?.override(imageAsset: primary ? .primaryButton : .secondaryButton) {
            self.setBackgroundImage(overrideImage, for: .normal)
            self.backgroundColor = .clear
            self.layer.cornerRadius = 0
            self.layer.borderWidth = 0
        }
        if let overrideColor = delegate?.override(colorAsset: primary ? .buttonPrimaryText : .buttonSecondaryText) {
            self.setTitleColor(overrideColor, for: .normal)
        }
    }
}

/// Helper for questionnaire items

extension Button {
    func roundButton() {
        self.round(radius: 15.0, borderWidth: 1.0, borderColor: self.isSelected ? .QBlueButtonHighlighted : .QGrayButton)
    }
}
