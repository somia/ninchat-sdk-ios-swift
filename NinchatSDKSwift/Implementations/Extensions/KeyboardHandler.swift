//
// Copyright (c) 21.10.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol KeyboardHandler {
    var scrollableView: UIView! { get }
    var onKeyboardSizeChanged: ((CGFloat) -> Void)? { get set }
}

extension KeyboardHandler where Self:UIViewController {
    var scrollableView: UIView! { self.view }

    func addKeyboardListeners() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            if let weakSelf = self, let keyboardSize = notification.keyboardInfo.endSize, let animationDuration = notification.keyboardInfo.animDuration, weakSelf.shouldBeScrolled(new: keyboardSize) {
                var height = keyboardSize.height
                if #available(iOS 11.0, *) {
                    height -= weakSelf.scrollableView.safeAreaInsets.bottom
                }
                weakSelf.scrollView(height: height, duration: animationDuration)
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notification in
            if let weakSelf = self, let animationDuration = notification.keyboardInfo.animDuration {
                weakSelf.scrollView(height: 0.0, duration: animationDuration)
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidChangeFrameNotification, object: nil, queue: .main) { [weak self] notification in
            let (oldSize, newSize, animationDuration) = notification.keyboardInfo
            if let weakSelf = self, oldSize != nil, newSize != nil, animationDuration != nil, weakSelf.shouldBeScrolled(new: newSize!, old: oldSize!) {
                var height = newSize!.height
                if #available(iOS 11.0, *) {
                    height -= weakSelf.scrollableView.safeAreaInsets.bottom
                }

                weakSelf.scrollView(height: height, duration: animationDuration!)
            }
        }
    }

    func removeKeyboardListeners() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }

    private func shouldBeScrolled(new newSize: CGRect, old oldSize: CGRect = .zero) -> Bool {
        guard newSize != oldSize, let focusedView: UIView = self.scrollableView.allSubviews.first(where: { $0.isFirstResponder && ($0 is UITextView || $0 is UITextField) }) else { return false }
        return (newSize.height < oldSize.height) ? true : UIScreen.main.bounds.height - newSize.height <= focusedView.convert(focusedView.bounds, to: nil).origin.y + focusedView.frame.size.height
    }

    private func scrollView(height: CGFloat, duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.scrollableView.transform = (height == 0) ? .identity : CGAffineTransform(translationX: 0, y: -height)
        }, completion: { [weak self] finished in
            self?.onKeyboardSizeChanged?(height)
        })
    }
}
