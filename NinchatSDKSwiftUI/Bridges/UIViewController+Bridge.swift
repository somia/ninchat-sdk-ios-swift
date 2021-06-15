//
// Copyright (c) 7.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

/// Titlebar implementation using SwiftUI

extension HasTitleBar where Self:ViewController {
    func addTitleBar(parent: UIView?, adjustToSafeArea: Bool, onCloseAction: @escaping () -> Void) {
        defer {
            self.adjustTitlebar(topView: parent, toSafeArea: adjustToSafeArea)
        }
        guard hasTitlebar else {
            return
        }

        var titlebarSwiftUI = Titlebar(self.sessionManager!,
                avatar: titlebarAvatar,
                defaultAvatar: (self as? HasDefaultAvatar)?.defaultAvatar,
                name: titlebarName, job: titlebarJob)
        titlebarSwiftUI.onCloseTapped = { onCloseAction() }

        let bar: UIView = UIHostingController(rootView: titlebarSwiftUI).view
        bar.backgroundColor = .clear

        self.shapeTitlebar(bar)
    }
}
