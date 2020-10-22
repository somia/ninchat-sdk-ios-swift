//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension UIViewController {
    func addRotationListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
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
        navigationController.topViewController?.supportedInterfaceOrientations ?? .all
    }
}

extension UIViewController: UITextViewDelegate {
    @available(iOS 10.0, *)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { true }
    
    @available(iOS, deprecated: 10.0)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool { true }
}
