//
// Copyright (c) 5.5.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

public enum CornerRadius: Equatable {
    case rounded // height / 2
    case curved(CGFloat)
    case noRadius
}

public protocol NinchatSwiftUIOverrideOptions {}

public protocol NinchatSwiftUITextOverrideOptions: NinchatSwiftUIOverrideOptions {
    var textColor: (Color?, UIColor?)? { get }
    var linkColor: (Color?, UIColor?)? { get }
    var font: (Font?, UIFont?)? { get }
}
public protocol NinchatSwiftUIViewOverridingOptions: NinchatSwiftUIOverrideOptions {
    var backgroundColor: (Color?, UIColor?)? { get }
}
public protocol NinchatSwiftUIButtonOverrideOptions: NinchatSwiftUIOverrideOptions {
    var foregroundColor: (Color?, UIColor?)? { get }
    var backgroundColor: (Color?, UIColor?)? { get }
    var cornerRadius: CornerRadius? { get }
    var borderColor: (Color?, UIColor?)? { get }
    var borderWidth: CGFloat? { get }
    var font: (Font?, UIFont?)? { get }
}

public enum SwiftUIConstants {
    case ninchatChatCloseButton
    case ninchatTextareaSubmitButton
    case ninchatPrimaryButton
    case ninchatSecondaryButton
    case ninchatChatCloseEmptyButton
    case ninchatModalTop
    case ninchatModalBottom
    case ninchatBackgroundTop
    case ninchatBackgroundBottom
    case ninchatWelcomeText
    case ninchatInfoText
    case ninchatQuestionnaireRadioSelected
    case ninchatQuestionnaireRadioUnselected
    case ninchatQuestionnaireNavigationNext
    case ninchatQuestionnaireNavigationBack
}
