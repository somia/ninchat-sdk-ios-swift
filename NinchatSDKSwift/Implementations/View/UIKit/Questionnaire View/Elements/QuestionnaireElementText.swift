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
            if let elements = configuration?.elements {
                self.shapeView(elements[index])
            } else {
                self.shapeView(configuration)
            }
        }
    }
    var elementHeight: CGFloat {
        self.height?.constant ?? 0
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
    }

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        self.initiateView()
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.initiateView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initiateView()
    }

    // MARK: - View Setup

    private func initiateView() {
        self.isEditable = false
        self.isScrollEnabled = false
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementText {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.textAlignment = .left
        self.setAttributed(text: configuration?.label ?? "", font: .ninchat)

        self.fix(height: max(32,0, self.estimateHeight(for: configuration?.label ?? "")))
    }

    private func estimateHeight(for text: String) -> CGFloat {
        if text.containsTags, let regex = try? NSRegularExpression(pattern: "</p>", options: .caseInsensitive), regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text)) > 0 {
            /// Using `intrinsicContentSize` for attributed strings with <p> tag results in incorrect height
            return self.intrinsicContentSize.height + 20.0
        }
        /// Could be calculated using regular `intrinsicContentSize` API
        return self.intrinsicContentSize.height
    }
}