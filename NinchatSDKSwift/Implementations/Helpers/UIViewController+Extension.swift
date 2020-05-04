//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol KeyboardHandler {
    var onKeyboardSizeChanged: ((CGFloat) -> Void)? { get set }
}

extension UIViewController {
    func addKeyboardListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidChangeSize(notification:)),
                name: UIWindow.keyboardDidChangeFrameNotification, object: nil)
    }

    func removeKeyboardListeners() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }
    
    @objc
    private func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            
            var height = keyboardSize.height
            if #available(iOS 11.0, *) {
                height -= view.safeAreaInsets.bottom
            }
            
            UIView.animate(withDuration: duration, animations: {
                self.view.transform = CGAffineTransform(translationX: 0, y: -height)
            }, completion: { finished in
                if let vc = self as? KeyboardHandler {
                    vc.onKeyboardSizeChanged?(height)
                }
            })
        }
    }

    @objc
    private func keyboardDidChangeSize(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {

            UIView.animate(withDuration: duration, animations: {
                self.view.transform = CGAffineTransform(translationX: 0, y: -keyboardSize.height)
            }, completion: { finished in
                if let vc = self as? KeyboardHandler {
                    vc.onKeyboardSizeChanged?(keyboardSize.height)
                }
            })
        }
    }

    @objc
    private func keyboardWillHide(notification: Notification) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            UIView.animate(withDuration: duration, animations: {
                self.view.transform = CGAffineTransform.identity
            }, completion: { finished in
                if let vc = self as? KeyboardHandler {
                    vc.onKeyboardSizeChanged?(0.0)
                }
            })
        }
    }
}

extension UIViewController {
    func addRotationListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(notification:)),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc
    func orientationChanged(notification: Notification) {
        fatalError("Should be overriden by the target")
    }
    
    func removeRotationListener() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

extension UIViewController: UINavigationControllerDelegate {
    @objc
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return navigationController.topViewController?.supportedInterfaceOrientations ?? .all
    }
}

extension UIViewController: UITextViewDelegate {
    @available(iOS 10.0, *)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
    
    @available(iOS, deprecated: 10.0)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
