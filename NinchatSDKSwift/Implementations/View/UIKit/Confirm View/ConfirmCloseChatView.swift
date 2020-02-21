//
// Copyright (c) 19.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

final class ConfirmCloseChatView: UIView, ConfirmView {
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var headerContainerView: UIView!
    @IBOutlet private(set) weak var bottomContainerView: UIView!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var infoTextView: UITextView!
    @IBOutlet private(set) weak var confirmButton: Button! {
        didSet {
            confirmButton.round(1.0)
        }
    }
    @IBOutlet private(set) weak var cancelButton: Button! {
        didSet {
            cancelButton.round(1.0, .defaultBackgroundButton)
        }
    }
    
    // MARK: - ConfirmView
    
    var onViewAction: OnViewAction?
    weak var session: NINChatSessionSwift? {
        didSet {
            self.overrideAssets()
        }
    }
        
    func overrideAssets() {
        confirmButton.overrideAssets(with: self.session, isPrimary: true)
        cancelButton.overrideAssets(with: self.session, isPrimary: false)
        
        if let backgroundColor = self.session?.override(colorAsset: .modalBackground) {
            self.headerContainerView.backgroundColor = backgroundColor
            self.bottomContainerView.backgroundColor = backgroundColor
        }
        
        if let textColor = self.session?.override(colorAsset: .modalText) {
            self.titleLabel.textColor = textColor
            self.infoTextView.textColor = textColor
        }
        
        guard let sessionManager = session?.sessionManager else { return }
        if let dialogTitle = sessionManager.siteConfiguration.confirmDialogTitle {
            self.infoTextView.setFormattedText(dialogTitle)
        }
        
        if let confirmText = sessionManager.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:]) {
            self.titleLabel.text = confirmText
            self.confirmButton.setTitle(confirmText, for: .normal)
        }
        
        if let cancelText = sessionManager.translate(key: Constants.kCancelDialog.rawValue, formatParams: [:]) {
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
