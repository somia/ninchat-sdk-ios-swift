//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementSelect: UIView, QuestionnaireElementWithTitle, QuestionnaireSettable, QuestionnaireOptionSelectableElement {

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var scaleToParent: Bool = false
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
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + 8
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
    }

    // MARK: - QuestionnaireSettable

    var presetAnswer: AnyHashable? {
        didSet {
            if let answer = self.presetAnswer as? String, let option = self.elementConfiguration?.options?.first(where: { $0.label == answer }) {
                self.select(option: option)
            }
            self.updateBorder()
        }
    }

    // MARK: - QuestionnaireOptionSelectableElement

    var onElementOptionSelected: ((ElementOption) -> ())?
    var onElementOptionDeselected: ((ElementOption) -> ())?

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var view: UIView = {
        UIView(frame: .zero)
    }()
    private(set) lazy var selectedOption: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var selectionIndicator: UIImageView = {
        UIImageView(image: UIImage(named: "icon_select_option", in: .SDKBundle, compatibleWith: nil), highlightedImage: UIImage(named: "icon_selected_option", in: .SDKBundle, compatibleWith: nil))
    }()
    private var dialogueIsShown = false

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
        self.view.addSubview(selectedOption)
        self.view.addSubview(selectionIndicator)
        self.selectedOption.text = "Select".localized
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onMenuTapped(_:))))
    }

    private func decorateView() {
        if self.view.subviews.count > 0 {
            self.layoutElementViews()

            selectedOption
                .fix(leading: (8.0, self.view), trailing: (8.0, self.view))
                .fix(top: (0.0, self.view), bottom: (0.0, self.view))
            selectionIndicator
                .fix(width: 15.0, height: 15.0)
                .fix(trailing: (15.0, self.view))
                .center(toY: self.view)
        }
    }

    // MARK: - User actions

    @objc
    private func onMenuTapped(_ sender: UITapGestureRecognizer) {
        self.endEditing(true)
        self.showOptions()
    }
}

extension QuestionnaireElementSelect {
    private func showOptions() {
        guard let options = self.elementConfiguration?.options?.compactMap({ $0.label }), options.count > 0 else { fatalError("There is no option to be shown!") }
        if dialogueIsShown { return }

        self.dialogueIsShown = true
        ChoiceDialogue.showDialogue(withOptions: options) { [unowned self] result in
            self.dialogueIsShown = false

            switch result {
            case .cancel:
                guard let option = self.elementConfiguration?.options?.first(where: { $0.label == self.selectedOption.text }) else { fatalError("Unable to deselect the option") }
                self.deselect(option: option)
            case .select(let index):
                guard let option = self.elementConfiguration?.options?[index] else { fatalError("Unable to pick selected option") }
                self.select(option: option)
            }
            self.updateBorder()
        }
    }

    private func select(option: ElementOption) {
        self.selectedOption.isHighlighted = true
        self.selectionIndicator.isHighlighted = true
        self.selectedOption.text = option.label
        self.onElementOptionSelected?(option)
    }

    func deselect(option: ElementOption) {
        self.selectedOption.isHighlighted = false
        self.selectionIndicator.isHighlighted = false
        self.selectedOption.text = "Select".localized
        self.onElementOptionDeselected?(option)
    }
}

extension QuestionnaireElementSelect: QuestionnaireElement {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.shapeTitle(configuration)

        self.view.backgroundColor = .clear
        self.view.fix(height: 45.0)
        self.selectedOption.font = .ninchat
        self.selectedOption.textAlignment = .left
        self.selectedOption.textColor = .QBlueButtonNormal
        self.selectedOption.highlightedTextColor = .QGrayButton
        self.selectionIndicator.contentMode = .scaleAspectFit

        self.elementConfiguration = configuration
        self.updateBorder()
    }
}

extension QuestionnaireElementSelect: QuestionnaireHasBorder {
    var isCompleted: Bool! {
        self.selectedOption.text != "Select".localized
    }

    func updateBorder() {
        self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: self.selectedOption.isHighlighted ? .QGrayButton : .QBlueButtonNormal)
        self.selectionIndicator.tintColor = self.selectedOption.isHighlighted ? .QGrayButton : .QBlueButtonNormal
    }
}
