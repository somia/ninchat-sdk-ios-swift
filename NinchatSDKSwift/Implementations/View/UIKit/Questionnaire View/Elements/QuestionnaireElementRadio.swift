//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementRadio: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireOptionSelectableElement {

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var scaleToParent: Bool = true
    var questionnaireConfiguration: QuestionnaireConfiguration? {
        didSet {
            if let elements = questionnaireConfiguration?.elements {
                self.shapeView(elements[index])
            } else {
                self.shapeView(questionnaireConfiguration)
            }

            self.decorateView()
        }
    }
    var elementConfiguration: QuestionnaireConfiguration?
    var elementHeight: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + (2 * 8.0)
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.overrideTitle(delegate: delegate)
        self.view.subviews.compactMap({ $0 as? Button }).forEach({ $0.overrideQuestionnaireAsset(with: delegate, isPrimary: $0.isSelected) })
    }

    // MARK: - QuestionnaireSettable

    var presetAnswer: AnyHashable? {
        didSet {
            if let answer = self.presetAnswer as? String,
               let option = self.elementConfiguration?.options?.first(where: { $0.label == answer }),
               let button = self.view.subviews.compactMap({ $0 as? Button }).first(where: { $0.titleLabel?.text == option.label }) {
                button.closure?(button)
            }
        }
    }

    // MARK: - QuestionnaireOptionSelectableElement

    var onElementOptionSelected: ((ElementOption) -> ())?
    var onElementOptionDeselected: ((ElementOption) -> ())?

    func deselect(option: ElementOption) {
        guard let tag = self.elementConfiguration?.options?.firstIndex(where: { $0.label == option.label }) else { return }
        (self.view.viewWithTag(tag + 1) as? Button)?.isSelected = false
        (self.view.viewWithTag(tag + 1) as? Button)?.roundButton()
    }

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions + QuestionnaireElementHasButtons

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
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

        self.decorateView()
        self.layoutIfNeeded()
    }

    // MARK: - View Setup

    private func initiateView() {
        self.addElementViews()
    }

    private func decorateView() {
        if self.view.subviews.count > 0 {
            self.layoutElementViews()
        }
    }
}

/// Subviews assets override
extension Button {
    fileprivate func overrideQuestionnaireAsset(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.titleLabel?.font = .ninchat

        self.setBackgroundImage((delegate?.override(questionnaireAsset: .radioSecondaryBackground) ?? UIColor.clear).toImage, for: .normal)
        self.setTitleColor(delegate?.override(questionnaireAsset: .radioSecondaryText) ?? UIColor.QGrayButton, for: .normal)

        self.setBackgroundImage((delegate?.override(questionnaireAsset: .radioPrimaryBackground) ?? UIColor.clear).toImage, for: .selected)
        self.setTitleColor(delegate?.override(questionnaireAsset: .radioPrimaryText) ?? UIColor.QBlueButtonNormal, for: .selected)

        self.roundButton()
    }
}

/// QuestionnaireElement
extension QuestionnaireElement where Self:QuestionnaireElementRadio {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.elementConfiguration = configuration

        self.shapeTitle(configuration)
        guard self.view.subviews.count == 0 else { return }
        self.shapeRadioView(configuration)
    }
}
