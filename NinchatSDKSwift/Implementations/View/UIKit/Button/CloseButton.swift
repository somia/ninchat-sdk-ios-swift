//
// Copyright (c) 14.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol CloseButtonProtocol {
    var closure: ((Button) -> Void)? { get set }
    var buttonTitle: String! { get set }
    
    func overrideAssets(with session: NINChatSessionInternalDelegate?)
}

final class CloseButton: UIView, CloseButtonProtocol {
    
    // MARK: - Outlets
    
    private(set) lazy var theButton: Button! = {
        let view = Button(frame: .zero)
        view.backgroundColor = .clear
        view.setTitleColor(.defaultBackgroundButton, for: .normal)
        view.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 24.0)
        
        return view
    }()
    private(set) lazy var closeButtonImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleToFill
        view.tintColor = .defaultBackgroundButton
        view.image = UIImage(named: "icon_close_x", in: .SDKBundle, compatibleWith: nil)
        
        return view
    }()
    
    // MARK: - CloseButtonProtocol
    
    var closure: ((Button) -> Void)? {
        didSet {
            self.theButton.closure = closure
        }
    }
    
    var buttonTitle: String! {
        didSet {
            self.theButton.setTitle(buttonTitle, for: .normal)
            self.theButton.sizeToFit()
        }
    }
    
    func overrideAssets(with session: NINChatSessionInternalDelegate?) {
        self.theButton.titleLabel?.font = .ninchat
        self.round(borderWidth: 1.0, borderColor: .defaultBackgroundButton)
        self.backgroundColor = .white

        if let overrideImage = session?.override(imageAsset: .chatCloseButton) {
            /// Overriding (setting) the button background image; no border.
            self.theButton.setBackgroundImage(overrideImage, for: .normal)
            self.theButton.contentMode = .scaleAspectFill
            self.theButton.backgroundColor = .clear
            self.theButton.layer.cornerRadius = 0
            self.theButton.layer.borderWidth = 0

            self.backgroundColor = .clear
            self.layer.cornerRadius = 0
            self.layer.borderWidth = 0
        }
        
        /// Handle overriding the button icon image
        if let icon = session?.override(imageAsset: .iconChatCloseButton) {
            self.closeButtonImageView.image = icon
        }
        
        /// Handle overriding the button text & border color
        if let textColor = session?.override(colorAsset: .buttonSecondaryText) {
            self.theButton.setTitleColor(textColor, for: .normal)
            self.closeButtonImageView.tintColor = textColor
            self.layer.borderColor = textColor.cgColor
        }

        self.updateConstraints()
    }
    
    // MARK: - UIView

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func setupView() {
        self.addSubview(theButton)
        self.theButton
            .fix(top: (0, self), bottom: (0, self))
            .fix(leading: (0, self), trailing: (0, self))
        
        self.addSubview(closeButtonImageView)
        self.closeButtonImageView
            .center(toY: self)
            .fix(width: 14.0, height: 14.0)
            .fix(trailing: (15, self))
        self.bringSubviewToFront(closeButtonImageView)
    }
    
    /// Update button's size constraints once the title is set
    override func updateConstraints() {
        super.updateConstraints()
        if let widthAnchor = self.width, let heightAnchor = self.height {
            widthAnchor.constant = (self.buttonTitle.isEmpty) ? 46.0 : self.theButton.frame.width + 66.0
            heightAnchor.constant = 46.0
        } else {
            /// only to set constraints, values are not important
            self.fix(width: 0.0, height: 0.0)
        }
        self.setupView()
    }
}
