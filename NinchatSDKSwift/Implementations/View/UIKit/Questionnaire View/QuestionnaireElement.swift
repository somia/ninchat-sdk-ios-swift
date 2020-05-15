//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol QuestionnaireElement: UIView {
    var configuration: ElementQuestionnaire? { get set }
    var onElementFocused: ((QuestionnaireElement) -> Void)? { get set }
    var onElementDismissed: ((QuestionnaireElement) -> Void)? { get set }

    func overrideAssets(with delegate: NINChatSessionInternalDelegate?, isPrimary: Bool)
    func shapeView()
}
extension QuestionnaireElement {
    func overrideAssets(with delegate: NINChatSessionInternalDelegate?) {
        self.overrideAssets(with: delegate, isPrimary: true)
    }
}

protocol QuestionnaireElementWithTitle: QuestionnaireElement {
    var onElementOptionFocused: ((ElementOption) -> Void)? { get set }

    associatedtype View: UIView
    var title: UILabel { get }
    var options: View { get }
    var scaleToParent: Bool { get set }

    func addElementViews()
    func layoutElementViews()
}
extension QuestionnaireElementWithTitle {
    func addElementViews() {
        /// Must be called in `view.awakeFromNib()` function

        self.addSubview(title)
        self.addSubview(options)
    }

    func layoutElementViews() {
        /// Must be called in `view.layoutSubviews()` function

        title
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self))
            .fix(height: self.title.intrinsicContentSize.height + 16.0)
        options
            .fix(leading: (8.0, self), trailing: (8.0, self))
            .fix(top: (0.0, self.title), isRelative: true)
            .fix(bottom: (8.0, self))
    }
}
