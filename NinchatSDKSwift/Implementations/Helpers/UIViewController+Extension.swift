//
//  UIViewController+Extension.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit

extension UIViewController {
    func addKeyboardListeners() {
        NotificationCenter.default.addObserver(self, selector: Selector(("keyboardWillShow")),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("keyboardWillHide")),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            
            var height = keyboardSize.height
            if #available(iOS 11.0, *) {
                height -= view.safeAreaInsets.bottom
            }
            UIView.animate(withDuration: duration) {
                self.view.transform = CGAffineTransform(translationX: 0, y: -height)
            }
        }
    }
    
    func removeKeyboardListeners() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillHide(notification: Notification) {
       if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            UIView.animate(withDuration: duration) {
                self.view.transform = CGAffineTransform.identity
            }
        }
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
    
    @available(iOS, deprecated: 9.0)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
