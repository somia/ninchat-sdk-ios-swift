//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementText: UITextView, QuestionnaireElement {

    fileprivate var conversationStylePadding: CGFloat {
        (self.questionnaireStyle == .conversation) ? 75 : 0
    }
    private var estimatedWidth: CGFloat {
        (UIApplication.topViewController()?.view.bounds ?? UIScreen.main.bounds).width - conversationStylePadding
    }

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var isShown: Bool? {
        didSet {
            self.isUserInteractionEnabled = isShown ?? true
        }
    }
    var questionnaireStyle: QuestionnaireStyle?
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
        self.estimateHeight(width: self.estimatedWidth)
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        if let overriddenColor = delegate?.override(questionnaireAsset: .titleTextColor) {
            self.setAttributed(text: self.elementConfiguration?.label ?? "", font: .ninchat, color: overriddenColor, width:  self.estimatedWidth - 24.0)
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

    func estimateHeight(width: CGFloat) -> CGFloat {
        max(24,0, self.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height)
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementText {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.textAlignment = .left
        self.backgroundColor = .clear
        self.setAttributed(text: configuration?.label ?? "", font: .ninchat, width: UIScreen.main.bounds.width - self.conversationStylePadding - 21.0)
        self.elementConfiguration = configuration
    }
}
