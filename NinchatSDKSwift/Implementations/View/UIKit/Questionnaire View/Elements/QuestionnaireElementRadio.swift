//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementRadio: UIView, QuestionnaireElementWithTitleAndOptions, QuestionnaireElementHasButtons {

    // MARK: - QuestionnaireElement

    var configuration: QuestionnaireConfiguration? {
        didSet {
            self.shapeView()
            self.shapeNavigationButtons()
            self.deactivate(constraints: [.height])
        }
    }
    var onElementOptionFocused: ((ElementOption) -> Void)?
    var scaleToParent: Bool = true

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.subviews.compactMap({ $0 as? Button }).forEach({ $0.overrideAssets(with: delegate, isPrimary: isPrimary) })
    }

    // MARK: - QuestionnaireElementHasButtons

    var onNextButtonTapped: ((ButtonQuestionnaire) -> Void)?
    var onBackButtonTapped: ((ButtonQuestionnaire) -> Void)?

    // MARK: - Subviews - QuestionnaireElementWithTitleAndOptions + QuestionnaireElementHasButtons

    typealias View = UIView
    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var view: View = {
        View(frame: .zero)
    }()
    private(set) lazy var buttons: UIView = {
        UIView(frame: .zero)
    }()

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        self.addElementViews()
        self.addNavigationButtons()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addElementViews()
        self.addNavigationButtons()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.addElementViews()
        self.addNavigationButtons()
    }
}

/// QuestionnaireElementHasButtons
extension QuestionnaireElementHasButtons where Self:QuestionnaireElementRadio {
    func shapeNavigationButtons() {
        guard let configuration = self.configuration?.buttons, configuration.hasValidButtons else { return }
        if configuration.hasValidBackButton {
            let view = Button(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onBackButtonTapped?(configuration)
            }
            self.shapeNavigationBack(button: view, configuration: configuration.next)
            self.buttons.addSubview(view)
        }
        if configuration.hasValidNextButton {
            let view = Button(frame: .zero) { [weak self] button in
                button.isSelected = !button.isSelected
                self?.onNextButtonTapped?(configuration)
            }
            self.shapeNavigationNext(button: view, configuration: configuration.back)
            self.buttons.addSubview(view)
        }

        self.layoutNavigationButtons()
    }
}

/// QuestionnaireElement
extension QuestionnaireElement where Self:QuestionnaireElementRadio {
    func shapeView() {
        self.title.font = .ninchat
        self.title.numberOfLines = 0
        self.title.textAlignment = .left
        self.title.lineBreakMode = .byWordWrapping
        self.title.text = self.configuration?.label

        if self.view.subviews.count == 0 {
            var upperView: UIView?
            self.configuration?.options?.forEach { [unowned self] option in
                let button = self.generateButton(for: option, tag: self.configuration?.options?.firstIndex(of: option) ?? -1)
                self.layoutButton(button, upperView: upperView)
                upperView = button
            }
            upperView?.fix(bottom: (8.0, self.view))
        }

        self.layoutElementViews()
    }

    private func generateButton(for option: ElementOption, tag: Int) -> Button {
        func roundButton(_ button: UIButton) {
            button.round(radius: 15.0, borderWidth: 1.0, borderColor: button.isSelected ? .QBlueButtonNormal : .QGrayButton)
        }

        let view = Button(frame: .zero) { [weak self] button in
            button.isSelected = !button.isSelected
            roundButton(button)
            self?.onElementOptionFocused?(option)
        }
        view.tag = tag
        view.setTitle(option.label, for: .normal)
        view.setTitleColor(.QGrayButton, for: .normal)
        view.setTitle(option.label, for: .selected)
        view.setTitleColor(.QBlueButtonNormal, for: .selected)
        roundButton(view)

        return view
    }

    private func layoutButton(_ button: UIView, upperView: UIView?) {
        self.view.addSubview(button)

        if self.scaleToParent {
            button
                .deactivate(constraints: [.width])
                .fix(leading: (8.0, self.view), trailing: (8.0, self.view))
        } else if self.width?.constant ?? 0 < self.intrinsicContentSize.width + 32.0 {
            button.fix(width: button.intrinsicContentSize.width + 32.0)
        }

        if let upperView = upperView {
            button.fix(top: (8.0, upperView), isRelative: true)
        } else {
            button.fix(top: (8.0, self.view), isRelative: true)
        }

        button.fix(height: max(45.0, self.intrinsicContentSize.height + 16.0))
    }
}
