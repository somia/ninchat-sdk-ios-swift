//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ChatViewProtocol: UIView {
    /** ChatView data source. */
    var dataSource: ChatViewDataSource? { get set }
    
    /** ChatView delegate. */
    var delegate: ChatViewDelegate? { get set }
    
    /** Chat session manager. */
    var sessionManager: NINChatSessionManager? { get set }
    
    /** A new message was added to given index. Updates the view. */
    func didAddMessage(at index: Int)
    
    /** A message was removed from given index. */
    func didRemoveMessage(from index: Int)

    /** A compose message got updates from the server regarding its options. */
    func didUpdateComposeAction(at index: Int, with action: ComposeUIAction)
    
    /** Should update table content offset when keyboard state changes. */
    func updateContentSize(_ value: CGFloat)
}

final class ChatView: UIView, ChatViewProtocol {
    /**
    * The image asset overrides as map. Only contains items used by chat view.
    * These are cached in this fashion to avoid looking them up from the chat delegate
    * every time a cell needs updating.
    */
    private var imageAssets: NINImageAssetDictionary!
    
    /**
    * The color asset overrides as map. Only contains items used by chat view.
    * These are cached in this fashion to avoid looking them up from the chat delegate
    * every time a cell needs updating.
    */
    private var colorAssets: NINColorAssetDictionary!
    
    /**
    * Current states for the visible ui/compose type messages, tracked across cell
    * recycle. messageID as key, array corresponds to the array of ui/compose objects
    * in the message with each object being a dictionary that gets received and passed
    * to NINUIComposeElement objects that are responsible for generating and reading it.
    */
    var composeMessageStates: [String:[Bool]]? = [:]
    
    /** Configuration for agent avatar. */
    private var agentAvatarConfig: AvatarConfig!
    
    /** Configuration for user avatar. */
    private var userAvatarConfig: AvatarConfig!
    
    private let videoThumbnailManager = VideoThumbnailManager()
    private var cellConstraints: Array<CGSize> = []
    private var composeCellActions: [Int:ComposeUIAction] = [:]

    /// To avoid a race condition in updating the chat view
    private let lock = NSLock()

    // MARK: - Outlets
    
    @IBOutlet private(set) weak var tableView: UITableView! {
        didSet {
            tableView.register(ChatChannelComposeCell.self)
            
            tableView.register(ChatChannelMediaMineCell.self)
            tableView.register(ChatChannelTextMineCell.self)
    
            tableView.register(ChatChannelMediaOthersCell.self)
            tableView.register(ChatChannelTextOthersCell.self)
            
            tableView.register(ChatTypingCell.self)
            tableView.register(ChatMetaCell.self)
            tableView.dataSource = self
            tableView.delegate = self
            
            /// Rotate the table view 180 degrees; we will use it upside down
            tableView.rotate()
            tableView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    // MARK: - ChatViewProtocol

    weak var sessionManager: NINChatSessionManager? {
        didSet {
            self.imageAssets = self.sessionManager?.delegate?.imageAssetsDictionary
            self.colorAssets = self.sessionManager?.delegate?.colorAssetsDictionary
            
            self.agentAvatarConfig = AvatarConfig(avatar: sessionManager?.siteConfiguration.agentAvatar, name: sessionManager?.siteConfiguration.agentName)
            self.userAvatarConfig = AvatarConfig(avatar: sessionManager?.siteConfiguration.userAvatar, name: sessionManager?.siteConfiguration.userName)
        }
    }
    weak var dataSource: ChatViewDataSource?
    weak var delegate: ChatViewDelegate?
    
    func didAddMessage(at index: Int) {
        guard let messageCount = dataSource?.numberOfMessages(for: self), tableView.numberOfRows(inSection: 0) < messageCount else { return }
        lock.lock()
        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        lock.unlock()
    }
    
    func didRemoveMessage(from index: Int) {
        guard let messageCount = dataSource?.numberOfMessages(for: self), tableView.numberOfRows(inSection: 0) > messageCount else { return }
        lock.lock()
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        lock.unlock()
    }

    func didUpdateComposeAction(at index: Int, with action: ComposeUIAction) {
        debugger("Got ui action update for compose for message at: \(index)")

        guard self.composeCellActions[index] == nil else { return }
        self.composeCellActions[index] = action
    }

    func updateContentSize(_ value: CGFloat) {
        self.tableView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: value, right: 0.0)
    }
    
    // MARK: - UIView
    
    deinit {
        debugger("`ChatView` deallocated")
    }
}

// MARK: - UITableViewDataSource - UITableViewDelegate

extension ChatView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.cellConstraints.insert(.zero, at: 0)
        return dataSource?.numberOfMessages(for: self) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = dataSource?.message(at: indexPath.row, self) else { fatalError("Unable to fetch chat cell") }
        
        if let channelMSG = message as? ChannelMessage {
            return setupBubbleCell(channelMSG, at: indexPath)
        } else if let typingMSG = message as? UserTypingMessage {
            return setupTypingCell(typingMSG, at: indexPath)
        } else if let metaMSG = message as? MetaMessage {
            return setupMetaCell(metaMSG, at: indexPath)
        }
        fatalError("Invalid message type")
    }

    private func cell(_ message: ChannelMessage, for tableView: UITableView, at index: IndexPath) -> ChatChannelCell {
        if let _ = message as? ComposeMessage {
            return tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelComposeCell
        } else if let text = message as? TextMessage {
            if let attachment = text.attachment, attachment.isImage || attachment.isVideo {
                return (text.mine) ? tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelMediaMineCell : tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelMediaOthersCell
            }
            return (text.mine) ? tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelTextMineCell : tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelTextOthersCell
        }
        fatalError("Unsupported cell type")
    }
}

// MARK: - Helper methods for Cell Setup

extension ChatView {
    private func setupBubbleCell(_ message: ChannelMessage, at indexPath: IndexPath) -> ChatChannelCell {
        let cell = self.cell(message, for: tableView, at: indexPath)
        cell.session = self.sessionManager
        cell.videoThumbnailManager = videoThumbnailManager

        cell.onComposeSendTapped = { [weak self] composeContentView, didUpdateOptions in
            guard didUpdateOptions else { return }
            self?.delegate?.didSendUIAction(composeContent: composeContentView)
        }
        cell.onComposeUpdateTapped = { [weak self] composeState, didUpdateOptions in
            guard didUpdateOptions else { return }
            self?.composeMessageStates?[message.messageID] = composeState
        }
        cell.onImageTapped = { [weak self] attachment, image in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.didSelect(image: image, for: attachment, weakSelf)
        }
        cell.onConstraintsUpdate = { [weak self] in
            DispatchQueue.global(qos: .background).async {
                cell.isReloading = true
                UIView.animate(withDuration: TimeConstants.kAnimationDuration.rawValue, animations: {
                    DispatchQueue.main.async {
                        guard self?.tableView.numberOfRows(inSection: 0) == self?.dataSource?.numberOfMessages(for: self!) else { return }

                        self?.tableView.beginUpdates()
                        self?.tableView.endUpdates()
                    }
                }, completion: { finished in
                    cell.isReloading = !finished
                })
            }
        }
        
        cell.populateChannel(message: message, configuration: self.sessionManager?.siteConfiguration, imageAssets: self.imageAssets, colorAssets: self.colorAssets, agentAvatarConfig: self.agentAvatarConfig, userAvatarConfig: self.userAvatarConfig, composeState: self.composeMessageStates?[message.messageID])
        if let cell = cell as? ChatChannelComposeCell {
            if let action = self.composeCellActions[indexPath.row] {
                cell.composeMessageView.updateStates(with: action)
                composeCellActions.removeValue(forKey: indexPath.row)
            }
        }
        return cell
    }

    private func setupTypingCell(_ message: UserTypingMessage, at indexPath: IndexPath) -> ChatTypingCell {
        let cell: ChatTypingCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.populateTyping(message: message, imageAssets: imageAssets, colorAssets: colorAssets, agentAvatarConfig: agentAvatarConfig)
        return cell
    }

    private func setupMetaCell(_ message: MetaMessage, at indexPath: IndexPath) -> ChatMetaCell {
        let cell: ChatMetaCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.delegate = self.sessionManager?.delegate
        cell.onCloseChatTapped = { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.didRequestToClose(weakSelf)
        }
        
        cell.populate(message: message, colorAssets: self.colorAssets)
        return cell
    }
}
