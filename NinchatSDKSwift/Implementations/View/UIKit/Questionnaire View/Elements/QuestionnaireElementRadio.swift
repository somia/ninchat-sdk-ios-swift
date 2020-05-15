//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class QuestionnaireElementRadio: UIView, QuestionnaireElementWithTitle {

    // MARK: - QuestionnaireElement

    var configuration: ElementQuestionnaire? {
        didSet {
            self.shapeView()
            self.deactivate(constraints: [.height])
        }
    }
    var onElementFocused: ((QuestionnaireElement) -> Void)?
    var onElementOptionFocused: ((ElementOption) -> Void)?
    var onElementDismissed: ((QuestionnaireElement) -> Void)? {
        didSet { fatalError("The closure won't be called on this type") }
    }
    var scaleToParent: Bool = true

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool) {
        self.subviews.compactMap({ $0 as? Button }).forEach({ $0.overrideAssets(with: delegate, isPrimary: isPrimary) })
    }

    // MARK: - Subviews - QuestionnaireElementWithTitle

    typealias View = UIView
    private(set) lazy var title: UILabel = {
        UILabel(frame: .zero)
    }()
    private(set) lazy var options: View = {
        View(frame: .zero)
    }()

    // MARK: - UIView life-cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        self.addElementViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutElementViews()
    }
}

extension QuestionnaireElementRadio {
    internal func generateButton(for option: ElementOption, tag: Int) -> Button {
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

    internal func layoutButton(_ button: UIView, upperView: UIView) {
        if self.scaleToParent {
            button
                .deactivate(constraints: [.width])
                .fix(leading: (8.0, self.options), trailing: (8.0, self.options))
        } else if self.width?.constant ?? 0 < self.intrinsicContentSize.width + 32.0 {
            button.fix(width: button.intrinsicContentSize.width + 32.0)
        }
        button
            .fix(top: (8.0, upperView), isRelative: true)
            .fix(height: max(45.0, self.intrinsicContentSize.height + 16.0))
    }
}

extension QuestionnaireElement where Self:QuestionnaireElementRadio {
    func shapeView() {
        self.title.font = .ninchat
        self.title.numberOfLines = 0
        self.title.textAlignment = .left
        self.title.lineBreakMode = .byWordWrapping
        self.title.text = self.configuration?.label

        if self.options.subviews.count == 0 {
            var upperView: UIView = self.title
            self.configuration?.options?.forEach { [unowned self] option in
                let button = self.generateButton(for: option, tag: 0)
                self.options.addSubview(button)
                self.layoutButton(button, upperView: upperView)
                upperView = button
            }
            upperView.fix(bottom: (8.0, self.options))
        }
    }
}