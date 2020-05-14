//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable

final class QuestionnaireElementButton: Button {

    var type: QuestionnaireButtonType!
    var configuration: QuestionnaireConfiguration? {
        didSet {
            self.shapeView()
        }
    }

    // MARK: - UIView life-cycle

    override var isEnabled: Bool {
        didSet {
            self.alpha = isEnabled ? 1.0 : 0.5
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.addTarget(self, action: #selector(touchUpInside(sender:)), for: .touchUpInside)
    }
}

extension QuestionnaireElementButton {
    private func shapeView() {
        guard self.type != nil else { fatalError("`Button` type needs to be declared first") }
        guard let buttons = self.configuration?.buttons else { fatalError("There are not any defined buttons for given type: \(self.type)") }

        switch self.type {
        case .next:
            guard self.addToSubview(buttons.next) else { self.removeFromSuperview(); return }
            self.shapeNext(button: buttons.next)
        case .back:
            guard self.addToSubview(buttons.back) else { self.removeFromSuperview(); return }
            self.shapeBack(button: buttons.back)
        default:
            fatalError("Unknown button type!")
        }

        self.titleLabel?.font = .ninchat
        self.imageEdgeInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        self
            .fix(width: max(80.0, self.intrinsicContentSize.width + 32.0), height: 45.0)
            .round(radius: 45.0 / 2, borderWidth: 1.0, borderColor: .QBlueButtonNormal)
    }

    private func addToSubview(_ button: AnyCodable) -> Bool {
        if let bool = button.value as? Bool {
            return bool
        } else if let string = button.value as? String {
            return !string.isEmpty
        }
        return false
    }

    private func shapeNext(button: AnyCodable) {
        if let _ = button.value as? Bool {
            self.setTitle("", for: .normal)
            self.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .normal)

            self.setTitle("", for: .selected)
            self.setImage(UIImage(named: "icon_select_next", in: .SDKBundle, compatibleWith: nil), for: .highlighted)
        } else if let title = button.value as? String {
            self.setTitle(title, for: .normal)
            self.setTitleColor(.white, for: .normal)
            self.setBackgroundImage(UIColor.QBlueButtonNormal.toImage, for: .normal)

            self.setTitle(title, for: .selected)
            self.setTitleColor(.white, for: .selected)
            self.setBackgroundImage(UIColor.QBlueButtonHighlighted.toImage, for: .highlighted)
        }
    }

    private func shapeBack(button: AnyCodable) {
        if let _ = button.value as? Bool {
            self.setTitle("", for: .normal)
            self.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .normal)

            self.setTitle("", for: .selected)
            self.setImage(UIImage(named: "icon_select_back", in: .SDKBundle, compatibleWith: nil), for: .selected)
        } else if let title = button.value as? String {
            self.setTitle(title, for: .normal)
            self.setTitleColor(.QBlueButtonNormal, for: .normal)
            self.setBackgroundImage(nil, for: .normal)

            self.setTitle(title, for: .selected)
            self.setTitleColor(.QBlueButtonHighlighted, for: .selected)
            self.setBackgroundImage(nil, for: .selected)
        }
    }
}