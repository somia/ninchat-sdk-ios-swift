//
// Copyright (c) 26.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension QuestionnaireElementWithTitle where View:UITextField {
    func shapeTextField(_ configuration: QuestionnaireConfiguration?) {
        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.borderStyle = .none
        self.view.font = .ninchat
        self.view.fix(height: 45.0)
    }
}

extension QuestionnaireElementWithTitle where View:UITextView {
    func shapeTextView(_ configuration: QuestionnaireConfiguration?) {
        self.view.backgroundColor = .clear
        self.view.textAlignment = .left
        self.view.font = .ninchat
        self.view.fix(height: 98.0)
    }
}
