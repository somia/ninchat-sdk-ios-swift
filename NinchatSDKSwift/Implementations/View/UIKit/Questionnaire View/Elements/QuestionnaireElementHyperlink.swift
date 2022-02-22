//
// Copyright (c) 21.1.2022 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class QuestionnaireElementHyperlink: UIView, QuestionnaireElement, HasExternalLink {

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var isShown: Bool? {
        didSet {
            self.isUserInteractionEnabled = isShown ?? true
        }
    }
    var scaleToParent: Bool = true
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
        self.delegate = delegate
        self.view.subviews.compactMap({ $0 as? NINButton }).forEach({ $0.overrideQuestionnaireAsset(with: delegate, isPrimary: false) })
    }

    // MARK: - HasExternalLink

    var didTapOnURL: ((URL?) -> Void)?

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions + QuestionnaireElementHasButtons

    private weak var delegate: NINChatSessionInternalDelegate?
    private(set) lazy var view: UIView = {
        UIView(frame: .zero)
    }()

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        self.initiateView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initiateView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initiateView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutIfNeeded()
    }

    // MARK: - View Setup

    internal func initiateView() {
        self.addSubview(view)
        view.layer.borderColor = UIColor.clear.cgColor

        view
                .fix(leading: (8.0, self), trailing: (8.0, self))
                .fix(top: (8.0, self))
                .center(toX: self)
        view.leading?.priority = .almostRequired
        view.trailing?.priority = .almostRequired
    }

    func shapeLinkView(_ configuration: QuestionnaireConfiguration?) {
        let view = NINButton(frame: .zero) { [weak self] button in
            guard let `self` = self else { return }

            if let url = self.elementConfiguration?.href {
                self.didTapOnURL?(URL(string: url))
            }
        }

        view.tag = tag + 1
        view.setTitle(self.elementConfiguration?.label ?? self.elementConfiguration?.href ?? "", for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setImage(UIImage(named: "icon-external-link", in: .SDKBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        view.imageView?.tintColor = view.titleColor(for: .normal)
        view.semanticContentAttribute = .forceRightToLeft
        view.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 0.0)
        view.updateTitleScale()

        self.layoutButton(view)
    }

    internal func layoutButton(_ button: NINButton) {
        self.view.addSubview(button)

        if self.scaleToParent {
            button.fix(leading: (0.0, self.view), trailing: (0.0, self.view))
            button.leading?.priority = .almostRequired
            button.trailing?.priority = .almostRequired
        } else if self.width?.constant ?? 0 < self.intrinsicContentSize.width + 32.0 {
            button.fix(width: button.intrinsicContentSize.width + 32.0)
        }
        button
                .fix(top: (4.0, self.view))
                .fix(height: max(45.0, button.intrinsicContentSize.height + 16.0))
                .center(toX: self.view)

        if self.view.height == nil {
            self.view.fix(height: 0)
        }
        view.height?.constant += button.height!.constant + 8
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementHyperlink {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        if self.didShapedView { return }

        self.elementConfiguration = configuration
        self.shapeLinkView(configuration)
        self.elementHeight = (self.view.height?.constant ?? 0) + 16
    }
}

extension NINButton {
    fileprivate func overrideQuestionnaireAsset(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.titleLabel?.font = .ninchat
        if let layer = delegate?.override(layerAsset: .ninchatQuestionnaireRadioUnselected) {
            self.layer.apply(layer)
        } else {
            self.roundButton()
        }
        self.setTitleColor(delegate?.override(questionnaireAsset: .ninchatQuestionnaireColorRadioUnselectedText) ?? .QGrayButton, for: .normal)
        self.imageView?.tintColor = self.titleColor(for: .normal)
    }
}
