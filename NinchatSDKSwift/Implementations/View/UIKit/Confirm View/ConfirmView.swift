//
// Copyright (c) 19.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

enum ConfirmAction {
    case confirm
    case cancel
}

protocol ConfirmView where Self:UIView {
    typealias OnViewAction = ((ConfirmAction) -> Void)
    var onViewAction: OnViewAction? { get set }
    var session: NINChatSessionSwift? { get set }
    
    func showConfirmView(on view: UIView)
    func hideConfirmView()
    func overrideAssets()
}

final class FadeView: UIView {}

extension ConfirmView {
    func showConfirmView(on view: UIView) {
        let fadeView = self.fadeView(on: view)
        view.addSubview(fadeView)
        fadeView
            .fix(leading: (0, view), trailing: (0, view))
            .fix(top: (0, view), bottom: (0, view))
        
        view.addSubview(self)
        self
            .fix(top: (0, view))
            .fix(leading: (0, view), trailing: (0, view))
        
        self.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
        self.hide(false, withActions: { [weak self] in
            self?.transform = .identity
        })
    }
    
    /// Create a "fade" view to fade out the background a bit and constrain it to match the view
    private func fadeView(on target: UIView) -> UIView {
        let view = FadeView(frame: target.bounds)
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector(("onDismissTapped:"))))
        
        return view
    }
}

extension ConfirmView {
    func hideConfirmView() {
        self.hide(true, withActions: { [weak self] in
            self?.transform = CGAffineTransform(translationX: 0, y: -(self?.bounds.height ?? 0))
        }, andCompletion: { [weak self] in
            self?.superview?.subviews.compactMap { $0 as? FadeView }.forEach { $0.removeFromSuperview() }
            self?.removeFromSuperview()
        })
    }
    
    private func onDismissTapped(_ sender: UIGestureRecognizer) {
        self.onViewAction?(.cancel)
    }
}
