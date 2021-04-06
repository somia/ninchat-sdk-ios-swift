//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol TopBarAction {
    var onDownloadTapped: (() -> Void)? { get set }
    var onCloseTapped: (() -> Void)? { get set }
}

protocol TopBarProtocol: UIView, TopBarAction {
    var delegate: InternalDelegate? { get set }
    var fileName: String! { get set }
    
    func overrideAssets()
}

final class TopBar: UIView, TopBarProtocol {
    
    // MARK: - TopBarProtocol

    var delegate: InternalDelegate?
    var fileName: String! {
        didSet {
            fileNameLabel.text = fileName
        }
    }
    
    // MARK: - TopBarAction
    
    var onDownloadTapped: (() -> Void)?
    var onCloseTapped: (() -> Void)?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var fileNameLabel: UILabel!
    @IBOutlet private(set) weak var downloadContainer: UIView! {
        didSet {
            downloadContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onDownloadButtonTapped(sender:))))
        }
    }
    @IBOutlet private(set) weak var downloadButton: UIImageView!
    @IBOutlet private(set) weak var closeContainer: UIView! {
        didSet {
            closeContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCloseButtonTapped(sender:))))
        }
    }
    @IBOutlet private(set) weak var closeButton: UIImageView!
    
    func overrideAssets() {
        if let downloadButton = self.delegate?.override(imageAsset: .ninchatIconDownload) {
            self.downloadButton.image = downloadButton
        }
        if let closeButton = self.delegate?.override(imageAsset: .iconChatCloseButton) {
            self.closeButton.image = closeButton
        }
    }
    
    // MARK: - User actions
    
    @objc
    private func onDownloadButtonTapped(sender: UIGestureRecognizer) {
        self.onDownloadTapped?()
    }
    
    @objc
    private func onCloseButtonTapped(sender: UIGestureRecognizer) {
        self.onCloseTapped?()
    }
}
