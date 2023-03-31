//
// Copyright (c) 11.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/// Titlebar implementation using UIKit

extension HasTitleBar where Self:ViewController {
    func addTitleBar(parent: UIView?, showAvatar: Bool? = nil, collapseCloseButton: Bool = false, adjustToSafeArea: Bool, onCloseAction: @escaping () -> Void) {
        defer {
            self.adjustTitlebar(topView: parent, toSafeArea: adjustToSafeArea)
        }
        guard hasTitlebar else {
            return
        }

        let titlebar: Titlebar = Titlebar.loadFromNib()
        titlebar.setupView(
            sessionManager,
            showAvatar,
            collapseCloseButton: collapseCloseButton,
            view: self,
            defaultAvatarView: self as? HasDefaultAvatar
        )
        titlebar.onCloseTapped = { onCloseAction() }

        self.shapeTitlebar(titlebar)
    }

    func updateTitlebar(showAvatar: Bool? = nil, collapseCloseButton: Bool = false) {
        guard let titlebar = self.view.allSubviews.compactMap({ $0 as? Titlebar }).first else { return }
        titlebar.setupView(
            sessionManager,
            showAvatar,
            collapseCloseButton: collapseCloseButton,
            view: self,
            defaultAvatarView: self as? HasDefaultAvatar
        )
    }
}
