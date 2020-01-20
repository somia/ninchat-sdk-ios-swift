//
// Copyright (c) 19.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

enum ConfrimAction {
    case confirm
    case cancel
}

protocol ConfirmView where Self:UIView {
    typealias OnViewAction = ((ConfrimAction) -> Void)
    var onViewAction: OnViewAction? { get set }
    var session: NINChatSessionSwift? { get set }
    
    func showConfrimView(on view: UIView)
    func hideConfrimView()
    func overrideAssets()
}

extension ConfirmView {
    func showConfrimView(on view: UIView) {
        let faderView = self.faderView(on: view)
        view.addSubview(faderView)
        faderView
            .fix(left: (0, view), right: (0, view), isRelative: false)
            .fix(top: (0, view), bottom: (0, view), isRelative: false)
        
        view.addSubview(self)
        self
            .fix(top: (0, view), isRelative: false)
            .fix(left: (0, view), right: (0, view), isRelative: false)
        
        self.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
        self.hide(false, withActions: { [weak self] in
            self?.transform = .identity
        })
    }
    
    /// Create a "fader" view to fade out the background a bit and constrain it to match the view
    private func faderView(on target: UIView) -> UIView {
        let view = UIView(frame: target.bounds)
        view.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        view.alpha = 0.0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector(("onDismissTapped:"))))
        
        return view
    }
}

extension ConfirmView {
    func hideConfrimView() {
        self.hide(true, withActions: { [weak self] in
            self?.transform = CGAffineTransform(translationX: 0, y: -(self?.bounds.height ?? 0))
        }, andCompletion: { [weak self] in
            self?.removeFromSuperview()
        })
    }
    
    private func onDismissTapped(_ sender: UIGestureRecognizer) {
        self.onViewAction?(.cancel)
    }
}
