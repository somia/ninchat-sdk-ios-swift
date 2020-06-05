//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementText: UITextView, QuestionnaireElement {

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var questionnaireConfiguration: QuestionnaireConfiguration? {
        didSet {
            if let elements = questionnaireConfiguration?.elements {
                self.shapeView(elements[index])
            } else {
                self.shapeView(questionnaireConfiguration)
            }
        }
    }
    var elementConfiguration: QuestionnaireConfiguration?
    var elementHeight: CGFloat {
        self.height?.constant ?? 0
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        if let overriddenColor = delegate?.override(questionnaireAsset: .titleTextColor) {
            self.setAttributed(text: self.elementConfiguration?.label ?? "", font: .ninchat, color: overriddenColor)
        }
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
        self.elementConfiguration = configuration

        self.fix(height: max(32,0, self.estimateHeight(for: configuration?.label ?? "")))
    }

    private func estimateHeight(for text: String) -> CGFloat {
        let size = self.sizeThatFits(CGSize(width: self.superview?.bounds.width ?? UIScreen.main.bounds.width, height: .greatestFiniteMagnitude))

        if text.containsTags, let regex = try? NSRegularExpression(pattern: "</p>", options: .caseInsensitive), regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text)) > 0 {
            return size.height + 20.0
        }
        return size.height
    }
}
