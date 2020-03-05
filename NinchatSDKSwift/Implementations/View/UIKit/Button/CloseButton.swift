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
        view.titleEdgeInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        
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
            self.updateConstraints()
        }
    }
    
    func overrideAssets(with session: NINChatSessionInternalDelegate?) {
        self.theButton.titleLabel?.font = .ninchat
        if let overrideImage = session?.override(imageAsset: .chatCloseButton) {
            /// Overriding (setting) the button background image; no border.
            self.theButton.setBackgroundImage(overrideImage, for: .normal)
            self.theButton.backgroundColor = .clear
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
    }
    
    // MARK: - UIView
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func setupView() {
        self.backgroundColor = .white
        self.round(1.0, .defaultBackgroundButton)
        
        self.addSubview(theButton)
        self.theButton
            .fix(top: (0, self), bottom: (0, self))
            .fix(leading: (0, self), trailing: (28, self))
        
        self.addSubview(closeButtonImageView)
        self.closeButtonImageView
            .center(toY: self)
            .fix(width: 14.0, height: 14.0)
            .fix(trailing: (14, self))
        self.bringSubviewToFront(closeButtonImageView)
    }
    
    /// Update button's size constraints once the title is set
    override func updateConstraints() {
        super.updateConstraints()
        self.deactivate(constraints: [.width, .height])
        self.fix(width: self.frame.width + 54.0, height: 44.0)
        self.setupView()
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
