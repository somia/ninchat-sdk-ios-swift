//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class QuestionnaireElementRadio: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireOptionSelectableElement {

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
        self.subviews.compactMap({ $0 as? Button }).forEach({ $0.overrideAssets(with: delegate, isPrimary: isPrimary) })
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

    internal func initiateView() {
        self.addElementViews()
    }

    internal func decorateView() {
        if self.view.subviews.count > 0 {
            self.layoutElementViews()
        }
    }
}

extension QuestionnaireElementRadio {
    func shapeRadioView(_ configuration: QuestionnaireConfiguration?) {
        var upperView: UIView?
        configuration?.options?.forEach { [unowned self] option in
            let button = self.generateButton(for: option, tag: (configuration?.options?.firstIndex(of: option))!)
            self.layoutButton(button, upperView: &upperView)
        }
    }

    internal func generateButton(for option: ElementOption, tag: Int) -> Button {
        let view = Button(frame: .zero) { [weak self] button in
            self?.applySelection(to: button)
            button.isSelected ? self?.onElementOptionSelected?(option) : self?.onElementOptionDeselected?(option)
        }

        view.tag = tag + 1
        view.setTitle(option.label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(option.label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        view.updateTitleScale()
        view.roundButton()

        return view
    }

    internal func layoutButton(_ button: UIView, upperView: inout UIView?) {
        self.view.addSubview(button)

        if self.scaleToParent {
            button.fix(leading: (8.0, self.view), trailing: (8.0, self.view))
            button.leading?.priority = .required
            button.trailing?.priority = .required
        } else if self.width?.constant ?? 0 < self.intrinsicContentSize.width + 32.0 {
            button.fix(width: button.intrinsicContentSize.width + 32.0)
        }
        if let upperView = upperView {
            button.fix(top: (8.0, upperView), isRelative: true)
        } else {
            button.fix(top: (8.0, self.view), isRelative: false)
        }
        button
                .fix(height: max(45.0, button.intrinsicContentSize.height + 16.0))
                .center(toX: self.view)

        if let height = self.view.height {
            height.constant += ((button.height?.constant ?? 0) + 8.0)
        } else {
            self.view.fix(height: (button.height?.constant ?? 0) + 16.0)
        }

        upperView = button
    }

    private func applySelection(to button: UIButton) {
        self.view.subviews.compactMap({ $0 as? Button }).forEach { button in
            button.isSelected = false
            (button as Button).roundButton()
        }
        button.isSelected = true
        (button as? Button)?.roundButton()
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
