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

extension HasTitleBar {
    func addTitleBar(onCloseAction: @escaping () -> Void) {
        fatalError("titlebar is not implemented")
    }
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
        guard let win = UIApplication.shared.windows.first(where: { $0.isKeyWindow })  else {
            return 70
        }
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            /// Don't apply safe area insets for iPad devices
            return 70
        }
        if #available(iOS 11.0, *) {
            return 55 + win.safeAreaInsets.top
        }
        return 70
    }

    internal var border: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .tTitleBorder
        return view
    }

    func overrideTitlebarAssets() {
        titlebar?.backgroundColor = .white

        if let layer = self.sessionManager?.delegate?.override(layerAsset: .ninchatModalTop) {
            titlebar?.layer.insertSublayer(layer, at: 0)
        }
    }

    internal func shapeTitlebar(_ bar: UIView) {
        guard let titlebar = self.titlebar else {
            fatalError("titlebar outlet is not set")
        }
        let border = self.border

        titlebar.addSubview(border)
        titlebar.addSubview(bar)

        bar
            .fix(top: (0, titlebar), toSafeArea: true)
            .fix(bottom: (0, titlebar))
            .fix(leading: (0, titlebar), trailing: (0, titlebar))
        bar.leading?.priority = .required
        bar.trailing?.priority = .required

        border
            .fix(bottom: (0, titlebar))
            .fix(leading: (0, titlebar), trailing: (0, titlebar))
            .fix(height: 1.0)
    }
}
