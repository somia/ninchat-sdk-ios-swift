//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension UIView {
    static func loadFromNib<T: UIView>(owner: AnyObject? = nil) -> T  {
        guard let bundle = Bundle.SDKBundle else {
            fatalError("Error getting SDK bundle")
        }
        let nib = UINib(nibName: String(describing: self), bundle: bundle)
        guard let view = nib.instantiate(withOwner: owner, options: nil).first as? T else {
            fatalError("Error loading \(String(describing: self)) from nib")
        }
        return view
    }
}

extension UIView {
    var hide: Bool {
        set {
            self.hide(newValue)
        }
        get {
            return self.alpha == 0
        }
    }
    
    func hide(_ hide: Bool, withActions action: (() -> Void)? = nil, andCompletion completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: TimeConstants.kAnimationDuration.rawValue, animations: {
            action?()
            self.alpha = (hide) ? 0.0 : 1.0
        }, completion: { finished in
            completion?()
        })
    }
    
    @discardableResult
    func round(radius: CGFloat? = nil, borderWidth: CGFloat = 0.0, borderColor: UIColor = .clear) -> Self {
        if let radius = radius {
            self.layer.cornerRadius = radius
        } else if let heightAnchor = self.height?.constant {
            self.layer.cornerRadius = heightAnchor / 2
        } else if self.bounds.height > 0 {
            self.layer.cornerRadius = self.bounds.height / 2
        }
        self.layer.masksToBounds = true
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        
        return self
    }
    
    func rotate(_ angle: CGFloat = .pi) {
        self.transform = CGAffineTransform(rotationAngle: angle)
    }
}

extension UIView {
    var allSubviews: [UIView] {
        if self.subviews.count == 0 {
            return []
        }
        return self.subviews + self.subviews.map({ $0.allSubviews }).joined()
    }
}

extension UIView {
    @objc
    func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            
            var height = keyboardSize.height
            if #available(iOS 11.0, *) {
                height -= self.safeAreaInsets.bottom
            }
            UIView.animate(withDuration: duration) {
                self.transform = CGAffineTransform(translationX: 0, y: -height)
            }
        }
    }
    
    @objc
    func keyboardWillHide(notification: Notification) {
       if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            UIView.animate(withDuration: duration) {
                self.transform = CGAffineTransform.identity
            }
        }
    }
}
