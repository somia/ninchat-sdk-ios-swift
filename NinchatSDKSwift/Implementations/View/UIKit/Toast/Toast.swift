//
// Copyright (c) 18.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

enum ToastType {
    case error(String)
    case info(String)

    var backgroundColor: UIColor? {
        switch self {
        case .info:
            return .toastInfoBackground
        case .error:
            return .toastErrBackground
        }
    }
    
    var value: String {
        switch self {
        case .info(let value):
            return value
        case .error(let value):
            return value
        }
    }
}

final class Toast: UIView {

    // MARK: - Outlets

    @IBOutlet private(set) weak var messageLabel: UILabel!
    
    // MARK: - Toast
    
    @discardableResult
    class func show(message: ToastType, onToastDismissed: (() -> Void)? = nil) -> Toast {
        let view: Toast = Toast.loadFromNib()
        
        DispatchQueue.main.async {
            view.messageLabel.text = message.value
            view.backgroundColor = message.backgroundColor ?? .gray

            add(view, to: UIApplication.shared.keyWindow)
            animateDialogue(view, hide: false, delay: 0.0) {
                /// After a delay, animate the toast out of sight again
                animateDialogue(view, hide: true, delay: TimeConstants.kBannerAnimationDuration.rawValue) {
                    onToastDismissed?()
                }
            }
        }
        return view
    }

    private class func add(_ view: UIView, to window: UIWindow?) {
        guard let parent = window else { return }

        parent.addSubview(view)
        view
            .fix(top: (0, parent), toSafeArea: false)
            .fix(leading: (0, parent), trailing: (0, parent))
            .transform = CGAffineTransform(translationX: 0, y: -view.bounds.height)
    }

    private class func animateDialogue(_ view: UIView, hide: Bool, delay: Double, completion: (() -> Void)? = nil) {
        view.hide(hide, delay: delay, withActions: { [weak view] in
            guard let `view` = view else { return }
            view.transform = (hide) ? CGAffineTransform(translationX: 0, y: -view.bounds.height) : .identity
        }, andCompletion: {
            completion?()
        })
    }
}
