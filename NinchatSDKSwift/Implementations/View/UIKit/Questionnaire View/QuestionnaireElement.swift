//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireElement: UIView {
    var configuration: ElementQuestionnaire? { get set }
    var onElementFocused: ((QuestionnaireElement) -> Void)? { get set }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool)
    func shapeView()
}
extension QuestionnaireElement {
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideAssets(with: delegate, isPrimary: true)
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