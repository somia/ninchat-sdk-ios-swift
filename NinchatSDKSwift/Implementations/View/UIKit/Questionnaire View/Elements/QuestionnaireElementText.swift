//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import WebKit

final class QuestionnaireElementText: WKWebView, QuestionnaireElement {

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
        self.height?.constant ?? self.scrollView.contentSize.height
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
    }

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        self.initiateView()
    }

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        self.initiateView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initiateView()
    }

    // MARK: - View Setup

    private func initiateView() {
        self.scrollView.bounces = false
        self.scrollView.isScrollEnabled = false
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementText {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.loadHTML(content: configuration?.label ?? "", font: UIFont.ninchat!)
        self.fix(height: self.estimateHeight(for: configuration?.label ?? ""))
    }

    private func estimateHeight(for text: String) -> CGFloat {
        /// Apparently Swift is unable to correctly calculate HTML string's bounds
        /// This is why we have to adjust it by adding padding values manually
        var height = text.htmlAttributedString(withFont: UIFont.ninchat, alignment: .left, color: .black)?.boundSize(maxSize: CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)).height ?? 0
        if text.containsTags, let regex = try? NSRegularExpression(pattern: "</p>", options: .caseInsensitive), regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text)) > 0 {
            height += CGFloat(regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text)) * 8) /// add 8pt extra space for every <p> tag
        }

        return height
    }
}
