//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementSelect: UIView, QuestionnaireElementWithTitle {

    internal var configuration: QuestionnaireConfiguration?
    var onOptionSelected: ((ElementOption) -> Void)?

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
    var onElementOptionTapped: ((ElementOption) -> Void)?
    var onElementFocused: ((QuestionnaireElement) -> Void)?
    var onElementDismissed: ((QuestionnaireElement) -> Void)?
    var elementHeight: CGFloat {
        CGFloat(self.title.height?.constant ?? 0) + CGFloat(self.view.height?.constant ?? 0) + 8
    }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
    }

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
        self.showOptions()
        self.onElementFocused?(self)
    }
}

extension QuestionnaireElementSelect {
    internal func updateSelectView() {
        self.view.round(radius: 6.0, borderWidth: 1.0, borderColor: self.selectedOption.isHighlighted ? .QGrayButton : .QBlueButtonNormal)
        self.selectionIndicator.tintColor = self.selectedOption.isHighlighted ? .QGrayButton : .QBlueButtonNormal
    }
}

extension QuestionnaireElementSelect {
    private func showOptions() {
        guard let options = self.configuration?.options?.compactMap({ $0.label }), options.count > 0 else { fatalError("There is no option to be shown!") }
        if dialogueIsShown { return }

        self.dialogueIsShown = true
        ChoiceDialogue.showDialogue(withOptions: options) { [unowned self] result in
            self.dialogueIsShown = false

            switch result {
            case .cancel:
                self.selectedOption.isHighlighted = false
                self.selectionIndicator.isHighlighted = false
                self.selectedOption.text = "Select".localized
                self.onElementDismissed?(self)
            case .select(let index):
                guard let option = self.configuration?.options?[index] else { fatalError("Unable to pick selected option") }
                self.selectedOption.isHighlighted = true
                self.selectionIndicator.isHighlighted = true
                self.selectedOption.text = option.label
                self.onOptionSelected?(option)
            }

            self.updateSelectView()
        }
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementSelect {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.shapeTitle(configuration)

        self.view.backgroundColor = .clear
        self.view.fix(height: 45.0)

        self.selectedOption.font = .ninchat
        self.selectedOption.textAlignment = .left
        self.selectedOption.textColor = .QBlueButtonNormal
        self.selectedOption.highlightedTextColor = .QGrayButton

        self.selectionIndicator.contentMode = .scaleAspectFit

        self.configuration = configuration
        self.updateSelectView()
    }
}
