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