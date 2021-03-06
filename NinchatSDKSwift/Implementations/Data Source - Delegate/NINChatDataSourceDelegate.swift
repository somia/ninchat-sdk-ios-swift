//
// Copyright (c) 25.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/** Delegate for the chat view. */
protocol ChatViewDelegate: AnyObject {
    /** An image in a cell was selected (tapped). */
    func didSelect(image: UIImage?, for attachment: FileInfo?, _ view: ChatView)
    
    /** "Close Chat" button was pressed inside the chat view; the used requests closing the chat SDK. */
    func didRequestToClose(_ view: ChatView)
    
    /** "Send" button was pressed in a ui/compose type message. */
    func didSendUIAction(composeContent: ComposeContentViewProtocol?)
}
protocol NINChatDelegate: ChatViewDelegate {
    var onOpenPhotoAttachment: ((UIImage, FileInfo) -> Void)? { get set }
    var onOpenVideoAttachment: ((FileInfo) -> Void)?  { get set }
    var onCloseChatTapped: (() -> Void)? { get set }
    var onUIActionError: ((Error) -> Void)? { get set }
}

/** Data source for the chat view. */
protocol ChatViewDataSource: AnyObject {
    /** How many messages there are. */
    func numberOfMessages(for view: ChatView) -> Int
    
    /** Returns the chat message at given index. */
    func message(at index: Int, _ view: ChatView) -> ChatMessage
}
protocol NINChatDataSource: ChatViewDataSource {
    init(viewModel: NINChatViewModel)
}

protocol NINChatDataSourceDelegate: NINChatDataSource, NINChatDelegate  {}

final class NINChatDataSourceDelegateImpl: NINChatDataSourceDelegate {
    
    private let viewModel: NINChatViewModel!
    
    // MARK: - NINChatDelegate
    
    var onOpenPhotoAttachment: ((UIImage, FileInfo) -> Void)?
    var onOpenVideoAttachment: ((FileInfo) -> Void)?
    var onCloseChatTapped: (() -> Void)?
    var onUIActionError: ((Error) -> Void)?
    
    // MARK: - NINChatDataSource
    
    init(viewModel: NINChatViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - ChatViewDataSource

extension NINChatDataSourceDelegateImpl {
    func numberOfMessages(for view: ChatView) -> Int {
        view.sessionManager?.chatMessages.count ?? 0
    }
    
    func message(at index: Int, _ view: ChatView) -> ChatMessage {
        guard let message = view.sessionManager?.chatMessages[index] else { fatalError("Unable to fetch chat message") }
        return message
    }
}

// MARK: - ChatViewDelegate

extension NINChatDataSourceDelegateImpl {
    func didSelect(image: UIImage?, for attachment: FileInfo?, _ view: ChatView) {
        guard let attachment = attachment else { return }
        
        if attachment.isImage, let image = image {
            self.onOpenPhotoAttachment?(image, attachment)
        } else if attachment.isVideo {
            self.onOpenVideoAttachment?(attachment)
        }
    }
    
    func didRequestToClose(_ view: ChatView) {
        self.onCloseChatTapped?()
    }
    
    func didSendUIAction(composeContent: ComposeContentViewProtocol?) {
        guard let composeContent = composeContent else { return }
        
        self.viewModel.send(action: composeContent) { [weak self] error in
            guard let err = error else { return }
            
            self?.onUIActionError?(err)
        }
    }
}
