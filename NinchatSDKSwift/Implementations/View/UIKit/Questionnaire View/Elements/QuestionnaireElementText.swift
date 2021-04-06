//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementText: UITextView, QuestionnaireElement {

    fileprivate var topInset: CGFloat {
        index == 0 ? 10.0 : 18.0
    }
    fileprivate var bottomInset: CGFloat {
        index == 0 ? 6.0 : 2.0
    }
    fileprivate var sidesInset: CGFloat {
        (self.questionnaireStyle == .conversation) ? 0.0 : 8.0
    }
    fileprivate var conversationStylePadding: CGFloat {
        (self.questionnaireStyle == .conversation) ? 32 : 0
    }

    // MARK: - QuestionnaireElement

    var index: Int = 0 {
        didSet {
            /// to remove text content paddings
            /// thanks to `https://stackoverflow.com/a/42333832/7264553`
            self.textContainerInset = UIEdgeInsets(top: topInset, left: sidesInset, bottom: bottomInset, right: sidesInset)
        }
    }
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
    var elementHeight: CGFloat = 0

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        if let overriddenColor = delegate?.override(questionnaireAsset: .titleTextColor) {
            self.setAttributed(text: self.elementConfiguration?.label ?? "", font: .ninchat, color: overriddenColor, width:  self.estimatedWidth())
        }
        if let linkColor = delegate?.override(colorAsset: .ninchatColorLink) {
            self.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
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

        self.textContainer.lineFragmentPadding = 0
    }

    func estimateHeight(width: CGFloat) -> CGFloat {
        self.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
    
    fileprivate func estimatedWidth() -> CGFloat {
        (UIApplication.topViewController()?.view.bounds ?? UIScreen.main.bounds).width - conversationStylePadding
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementText {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.textAlignment = .left
        self.backgroundColor = .clear
        self.setAttributed(text: configuration?.label ?? "", font: .ninchat, width: self.estimatedWidth())
        self.elementConfiguration = configuration
        self.elementHeight = self.estimateHeight(width: self.estimatedWidth()) + topInset
    }
}
