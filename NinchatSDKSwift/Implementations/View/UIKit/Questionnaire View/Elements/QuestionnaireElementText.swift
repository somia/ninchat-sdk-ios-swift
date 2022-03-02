//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementText: UITextView, QuestionnaireElement, HasTitle {

    fileprivate var topInset: CGFloat {
        index == 0 ? 18.0 : 24.0
    }
    fileprivate var bottomInset: CGFloat {
        index == 0 ? 6.0 : 2.0
    }
    fileprivate var conversationStylePadding: CGFloat {
        (self.questionnaireStyle == .conversation) ? 32 : 0
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
    var elementHeight: CGFloat = 0

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        if let overriddenColor = delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorTitleText) {
            self.setAttributed(text: self.elementConfiguration?.label ?? "", font: .ninchat, color: overriddenColor)
        }
        if let linkColor = delegate?.override(colorAsset: .ninchatColorLink) {
            self.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
        }
    }

    // MARK: - HasTitle
    
    var titleView: UIView {
        self
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
        
        self.textContainerInset = UIEdgeInsets(top: topInset, left: 0.0, bottom: bottomInset, right: 0.0)
        self.textContainer.lineFragmentPadding = 0
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementText {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.textAlignment = .left
        self.backgroundColor = .clear
        self.setAttributed(text: configuration?.label ?? "", font: .ninchat)
        self.elementConfiguration = configuration
    }
}
