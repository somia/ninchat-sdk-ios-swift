//
//  NINChatDataSource.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 25.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import Foundation
import NinchatSDK

protocol NINChatDelegate: NINChatViewDelegate {
    var onOpenPhotoAttachment: ((UIImage, NINFileInfo) -> Void)? { get set }
    var onOpenVideoAttachment: ((NINFileInfo) -> Void)?  { get set }
    var onCloseChatTapped: (() -> Void)? { get set }
    var onUIActionError: ((Error) -> Void)? { get set }
}

protocol NINChatDataSource: NINChatViewDataSource {
    init(viewModel: NINChatViewModel)
}

protocol NINChatDataSourceDelegate: NINChatDataSource, NINChatDelegate {}

final class NINChatDataSourceDelegateImpl: NINChatDataSourceDelegate {
    
    private let viewModel: NINChatViewModel!
    
    // MARK: - NINChatDelegate
    
    var onOpenPhotoAttachment: ((UIImage, NINFileInfo) -> Void)?
    var onOpenVideoAttachment: ((NINFileInfo) -> Void)?
    var onCloseChatTapped: (() -> Void)?
    var onUIActionError: ((Error) -> Void)?
    
    // MARK: - NINChatDataSource
    
    init(viewModel: NINChatViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - NINChatViewDataSource

extension NINChatDataSourceDelegateImpl {
    func numberOfMessages(for chatView: NINChatView!) -> Int {
        return chatView.sessionManager.chatMessages.count
    }
    
    func chatView(_ chatView: NINChatView!, messageAt index: Int) -> NINChatMessage! {
        return chatView.sessionManager.chatMessages[index]
    }
}

// MARK: - NINChatViewDelegate

extension NINChatDataSourceDelegateImpl {
    func chatView(_ chatView: NINChatView!, imageSelected image: UIImage!, forAttachment attachment: NINFileInfo!) {
        if attachment.isImage() {
            self.onOpenPhotoAttachment?(image, attachment)
        } else if attachment.isVideo() {
            self.onOpenVideoAttachment?(attachment)
        }
    }
    
    func closeChatRequested(by chatView: NINChatView!) {
        self.onCloseChatTapped?()
    }
    
    func uiActionSent(by composeContentView: NINComposeContentView!) {
        self.viewModel.send(action: composeContentView) { [weak self] error in
            guard let err = error else { return }
            
            composeContentView.sendActionFailed()
            self?.onUIActionError?(err)
        }
    }
}
