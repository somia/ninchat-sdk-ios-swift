//
// Copyright (c) 19.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class ConfirmCloseChatView: UIView, ConfirmView {
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var headerContainerView: UIView!
    @IBOutlet private(set) weak var bottomContainerView: UIView!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var infoTextView: UITextView!
    @IBOutlet private(set) weak var confirmButton: Button! {
        didSet {
            confirmButton.round(borderWidth: 1.0)
        }
    }
    @IBOutlet private(set) weak var cancelButton: Button! {
        didSet {
            cancelButton.round(borderWidth: 1.0, borderColor: .defaultBackgroundButton)
        }
    }
    
    // MARK: - ConfirmView
    
    var onViewAction: OnViewAction?
    var delegate: InternalDelegate?
    var sessionManager: NINChatSessionManager? {
        didSet {
            self.overrideAssets()
        }
    }
        
    func overrideAssets() {
        confirmButton.overrideAssets(with: self.delegate, isPrimary: true)
        cancelButton.overrideAssets(with: self.delegate, isPrimary: false)

        if let backgroundColor = self.delegate?.override(colorAsset: .modalBackground) {
            self.headerContainerView.backgroundColor = backgroundColor
            self.bottomContainerView.backgroundColor = backgroundColor
        }
        
        if let textColor = self.delegate?.override(colorAsset: .modalText) {
            self.titleLabel.textColor = textColor
            self.infoTextView.textColor = textColor
        }
        
        if let dialogTitle = sessionManager?.siteConfiguration.confirmDialogTitle {
            self.infoTextView.setAttributed(text: dialogTitle, font: .ninchat)
        }
        
        if let confirmText = sessionManager?.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) {
            self.titleLabel.text = confirmText
            self.confirmButton.setTitle(confirmText, for: .normal)
        }
        
        if let cancelText = sessionManager?.translate(key: Constants.kCancelDialog.rawValue, formatParams: [:]) {
            self.cancelButton.setTitle(cancelText, for: .normal)
        }
    }
    
    // MARK: - User actions
    
    @IBAction private func onConfirmButtonTapped(sender: UIButton) {
        self.onViewAction?(.confirm)
    }
    
    @IBAction private func onCancelButtonTapped(sender: UIButton) {
        self.onViewAction?(.cancel)
    }
}
