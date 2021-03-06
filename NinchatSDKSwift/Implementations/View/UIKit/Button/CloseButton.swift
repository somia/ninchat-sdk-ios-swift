//
// Copyright (c) 14.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol CloseButtonProtocol {
    var closure: ((NINButton) -> Void)? { get set }
    var buttonTitle: String! { get set }
    
    func overrideAssets(with session: NINChatSessionInternalDelegate?)
}

final class CloseButton: UIView, HasCustomLayer, CloseButtonProtocol {
    
    // MARK: - Outlets
    
    private(set) lazy var theButton: NINButton! = {
        let view = NINButton(frame: .zero)
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
    
    var closure: ((NINButton) -> Void)? {
        didSet {
            self.theButton.closure = closure
        }
    }
    var buttonTitle: String! = "" {
        didSet {
            self.theButton.setTitle(buttonTitle, for: .normal)
            self.theButton.sizeToFit()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyLayerOverride(view: self)
    }
    
    func overrideAssets(with session: NINChatSessionInternalDelegate?) {
        self.theButton.titleLabel?.font = .ninchat
        self.backgroundColor = .clear

        if buttonTitle.isEmpty, let layer = session?.override(layerAsset: .ninchatChatCloseEmptyButton) {
            self.layer.insertSublayer(layer, at: 0)
        } else if let layer = session?.override(layerAsset: .ninchatChatCloseButton) {
            self.layer.insertSublayer(layer, at: 0)
        } else {
            /// TODO: REMOVE legacy delegates

            func shapeButton(image: UIImage) {
                /// Overriding (setting) the button background image; no border.
                self.theButton.setBackgroundImage(image, for: .normal)
                self.theButton.contentMode = .scaleAspectFill
                self.theButton.backgroundColor = .clear
                self.theButton.layer.cornerRadius = 0
                self.theButton.layer.borderWidth = 0
            }

            self.round(borderWidth: 1.0, borderColor: .defaultBackgroundButton)
            self.backgroundColor = .white

            if let backgroundColor = session?.override(colorAsset: .chatCloseButtonBackground) {
                self.backgroundColor = backgroundColor
            }
            if buttonTitle.isEmpty, let overrideImage = session?.override(imageAsset: .chatCloseButtonEmpty) {
                shapeButton(image: overrideImage)
            } else if let overrideImage = session?.override(imageAsset: .chatCloseButton) {
                shapeButton(image: overrideImage)
            }
            if let icon = session?.override(imageAsset: .iconChatCloseButton) {
                self.closeButtonImageView.image = icon
            }
        }
        
        if let textColor = session?.override(colorAsset: .ninchatColorButtonCloseChatText) {
            self.theButton.setTitleColor(textColor, for: .normal)
            self.closeButtonImageView.tintColor = textColor
        } else if let textColor = session?.override(colorAsset: .ninchatColorButtonSecondaryText) {
            self.theButton.setTitleColor(textColor, for: .normal)
            self.closeButtonImageView.tintColor = textColor
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
            widthAnchor.constant = (self.buttonTitle.isEmpty) ? 45.0 : self.theButton.frame.width + 65.0
            heightAnchor.constant = 45.0
        } else {
            /// only to set constraints, values are not important
            self.fix(width: 0.0, height: 0.0)
        }
        self.setupView()
    }
}
