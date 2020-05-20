//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementText: UITextView, QuestionnaireElement {

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var configuration: QuestionnaireConfiguration? {
        didSet {
            self.shapeView(configuration)
        }
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
    }

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        self.deactivate(constraints: [.height])
        self.isEditable = false
        self.isScrollEnabled = false
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementText {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.textAlignment = .left
        self.setAttributed(text: self.configuration?.label ?? "", font: .ninchat)

        self.fix(height: max(24,0, self.intrinsicContentSize.height))
    }
}