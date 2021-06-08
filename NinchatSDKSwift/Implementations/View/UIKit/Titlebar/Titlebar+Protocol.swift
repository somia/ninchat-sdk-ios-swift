//
// Copyright (c) 8.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol HasDefaultAvatar {
    var defaultAvatar: UIImage? { get }
}

protocol HasTitleBar {
    func addTitleBar(onCloseAction: @escaping () -> Void)
    func overrideTitlebarAssets()

    var hasTitlebar: Bool { get }
    var titleHeight: CGFloat { get }
    var titlebar: UIView? { get }

    var titlebarAvatar: String? { get }
    var titlebarName: String? { get }
    var titlebarJob: String? { get }
}

extension HasTitleBar where Self:ViewController {
    var hasTitlebar: Bool {
        guard let session = self.sessionManager else {
            fatalError("session manager is not set!")
        }
        if session.siteConfiguration.hideTitlebar {
            /// hide title bar only if explicitly set in the config
            return false
        }
        return true
    }

    var titleHeight: CGFloat {
        guard let win = UIApplication.shared.windows.first(where: { $0.isKeyWindow })  else { return 70 }
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            /// Don't apply safe area insets for iPad devices
            return 70
        }
        return 70 + win.safeAreaInsets.top
    }

    internal var border: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .tTitleBorder
        return view
    }

    func overrideTitlebarAssets() {
        if let layer = self.sessionManager?.delegate?.override(layerAsset: .ninchatModalTop) {
            titlebar?.layer.insertSublayer(layer, at: 0)
        }
    }
}
