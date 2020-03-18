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
        default:
            return nil
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

    @IBOutlet private(set) weak var containerView: UIView!
    @IBOutlet private(set) weak var messageLabel: UILabel!

    // MARK: - Toast

    private var onToastTouched: (() -> Void)?
    private var onToastDismissed: (() -> Void)?

    class func show(message: ToastType, onToastTouched: (() -> Void)? = nil, onToastDismissed: (() -> Void)? = nil) {
        let view: Toast = Toast.loadFromNib()
        view.show(message: message, onToastTouched: onToastTouched, onToastDismissed: onToastDismissed)
    }

    internal func show(message: ToastType, onToastTouched: (() -> Void)?, onToastDismissed: (() -> Void)?) {
        self.onToastTouched = onToastTouched
        self.onToastDismissed = onToastDismissed
        self.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
        self.messageLabel.text = message.value
        if let bgColor = message.backgroundColor {
            self.containerView.backgroundColor = bgColor
        }

        self.addView(to: UIApplication.shared.keyWindow)
        self.animateDialogue(hide: false, delay: 0.0) {
            /// After a delay, animate the toast out of sight again
            self.animateDialogue(hide: true, delay: TimeConstants.kAnimationDelay.rawValue) {
                self.onViewDismissed()
            }
        }
    }

    private func addView(to window: UIWindow?) {
        guard let parent = window else { return }

        parent.addSubview(self)
        self
            .fix(top: (0, parent), toSafeArea: true)
            .fix(leading: (0, parent), trailing: (0, parent))
            .addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:))))
    }

    private func animateDialogue(hide: Bool, delay: Double, completion: (() -> Void)? = nil) {
        self.hide(hide, delay: delay, withActions: { [weak self] in
            self?.transform = (hide) ? CGAffineTransform(translationX: 0, y: -(self?.bounds.height ?? 0)) : .identity
        }, andCompletion: {
            completion?()
        })
    }

    // MARK: - User actions

    @objc
    internal func onViewTapped(_ sender: UIGestureRecognizer?) {
        self.onToastTouched?()
    }

    internal func onViewDismissed() {
        self.removeFromSuperview()
        self.onToastDismissed?()
    }
}