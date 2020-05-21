//
// Copyright (c) 14.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementSelect: UIView, QuestionnaireElement {

    var onOptionSelected: ((ElementOption) -> Void)?

    // MARK: - QuestionnaireElement

    var index: Int = 0
    var configuration: QuestionnaireConfiguration? {
        didSet {
            self.shapeView(configuration)
        }
    }
    var onElementFocused: ((QuestionnaireElement) -> Void)?
    var onElementDismissed: ((QuestionnaireElement) -> Void)?

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        #warning("Override assets")
    }

    // MARK: - Subviews

    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var menu: UIView = {
        UIView(frame: .zero)
    }()
    private(set) lazy var selectedOption: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var selectionIndicator: UIImageView = {
        UIImageView(image: UIImage(named: "icon_select_option", in: .SDKBundle, compatibleWith: nil))
    }()
    private var dialogueIsShown = false

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        self.addSubview(title)
        self.addSubview(menu)
        self.menu.addSubview(selectedOption)
        self.menu.addSubview(selectionIndicator)
        self.selectedOption.text = "Select".localized
        self.menu.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onMenuTapped(_:))))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.deactivate(constraints: [.height])
        title
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self))
            .fix(height: self.title.intrinsicContentSize.height + 16.0)
        menu
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self.title), isRelative: true)
            .fix(bottom: (8.0, self))
            .fix(height: 45.0)
        selectedOption
            .fix(leading: (8.0, self.menu), trailing: (8.0, self.menu))
            .fix(top: (0.0, self.menu), bottom: (0.0, self.menu))
        selectionIndicator
            .fix(width: 15.0, height: 15.0)
            .fix(trailing: (15.0, self.menu))
            .center(toY: self.menu)
    }

    // MARK: - User actions

    @objc
    private func onMenuTapped(_ sender: UITapGestureRecognizer) {
        self.showOptions()
        self.onElementFocused?(self)
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
                self.onElementDismissed?(self)
            case .select(let index):
                guard let option = self.configuration?.options?[index] else { fatalError("Unable to pick selected option") }
                self.onOptionSelected?(option)
            }
        }
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementSelect {
    func shapeView(_ configuration: QuestionnaireConfiguration?) {
        self.title.text = self.configuration?.label
        self.title.textAlignment = .left
        self.title.font = .ninchat

        self.menu.backgroundColor = .clear
        self.menu.round(radius: 6.0, borderWidth: 1.0, borderColor: .QBlueButtonNormal)

        self.selectedOption.textAlignment = .left
        self.selectedOption.font = .ninchat
        self.selectedOption.textColor = .QBlueButtonNormal

        self.selectionIndicator.contentMode = .scaleAspectFit
    }
}