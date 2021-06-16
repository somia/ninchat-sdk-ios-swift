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
    func addTitleBar(parent: UIView?, adjustToSafeArea: Bool, onCloseAction: @escaping () -> Void)
    func overrideTitlebarAssets()

    var hasTitlebar: Bool { get }
    var titlebar: UIView? { get }
    var titlebarContainer: UIView? { get }

    var titlebarAvatar: String? { get }
    var titlebarName: String? { get }
    var titlebarJob: String? { get }
}

extension HasTitleBar {
    func addTitleBar(parent: UIView?, adjustToSafeArea: Bool, onCloseAction: @escaping () -> Void) {
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

    internal var titleHeight: CGFloat {
        60.0
    }

    internal var border: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .tTitleBorder
        return view
    }

    func overrideTitlebarAssets() {
        titlebar?.backgroundColor = .clear
        titlebarContainer?.backgroundColor = .white

        if let layer = self.sessionManager?.delegate?.override(layerAsset: .ninchatModalTop) {
            titlebarContainer?.layer.insertSublayer(layer, at: 0)
        }
    }

    internal func shapeTitlebar(_ bar: UIView) {
        guard let titlebar = self.titlebar else {
            fatalError("titlebar outlet is not set")
        }
        guard self.titlebarContainer != nil else {
            fatalError("titlebar container outlet is not set")
        }
        titlebar.height?.constant = titleHeight

        titlebar.addSubview(bar)
        bar
            .fix(top: (0, titlebar))
            .fix(leading: (0, titlebar), trailing: (0, titlebar))
            .fix(height: titleHeight)
        bar.leading?.priority = .required
        bar.trailing?.priority = .required

        let border = self.border
        titlebar.addSubview(border)
        border
            .fix(bottom: (0, titlebar))
            .fix(leading: (0, titlebar), trailing: (0, titlebar))
            .fix(height: 1.0)


    }

    internal func adjustTitlebar(topView: UIView?, toSafeArea: Bool) {
        guard !self.hasTitlebar else { return }

        /// remove titlebar from parent
        titlebar?.removeFromSuperview()

        guard let topView = topView else { return }
        /// adjust top view when titlebar is hidden
        topView.fix(top: (0, self.view), toSafeArea: toSafeArea)
        topView.height?.constant += titleHeight
    }
}
