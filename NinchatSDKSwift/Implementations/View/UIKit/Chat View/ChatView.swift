//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

protocol ChatViewProtocol: UIView {
    /** ChatView data source. */
    var dataSource: ChatViewDataSource! { get set }
    
    /** ChatView delegate. */
    var delegate: ChatViewDelegate! { get set }
    
    /** Chat session manager. */
    var sessionManager: NINChatSessionManager! { get set }
    
    /** A new message was added to given index. Updates the view. */
    func didAddMessage(at index: Int)
    
    /** A message was removed from given index. */
    func didRemoveMessage(from index: Int)
    
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
    var composeMessageStates: [String:[Any]]? = [:]
    
    /** Configuration for agent avatar. */
    private var agentAvatarConfig: NINAvatarConfig!
    
    /** Configuration for user avatar. */
    private var userAvatarConfig: NINAvatarConfig!
    
    private let videoThumbnailManager = NINVideoThumbnailManager()
    private var cellConstraints: Array<CGSize> = []
    
    // MARK: - Outlets
    
    @IBOutlet private weak var tableView: UITableView! {
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
    
    private var cell: ((NINChannelMessage, UITableView, IndexPath) -> ChatChannelCell) = { (message, tableView, index) -> ChatChannelCell in
        if let compose = message as? NINUIComposeMessage {
            return tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelComposeCell
        } else if let text = message as? NINTextMessage {
            if let attachment = text.attachment, attachment.isImage || attachment.isVideo {
                return (text.mine) ? tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelMediaMineCell : tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelMediaOthersCell
            }
            return (text.mine) ? tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelTextMineCell : tableView.dequeueReusableCell(forIndexPath: index) as ChatChannelTextOthersCell
        }
        fatalError("Unsupported cell type")
    }
    
    // MARK: - ChatViewProtocol
    
    var dataSource: ChatViewDataSource!
    var delegate: ChatViewDelegate!
    var sessionManager: NINChatSessionManager! {
        didSet {
            self.imageAssets = self.imageAssetsDictionary
            self.colorAssets = self.colorAssetsDictionary
            
            self.agentAvatarConfig = NINAvatarConfig(avatar: sessionManager.siteConfiguration.agentAvatar ?? "",
                                                     name: sessionManager.siteConfiguration.agentName ?? "")
            self.userAvatarConfig = NINAvatarConfig(avatar: sessionManager.siteConfiguration.userAvatar ?? "",
                                                    name: sessionManager.siteConfiguration.userName ?? "")
        }
    }
    
    func didAddMessage(at index: Int) {
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    func didRemoveMessage(from index: Int) {
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    func updateContentSize(_ value: CGFloat) {
        self.tableView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: value, right: 0.0)
    }
    
    // MARK: - UIView
    
    deinit {
        debugger("`ChatView` deallocated")
    }
}

// MARK: - Helper methods for assets

extension ChatView {
    var imageAssetsDictionary: NINImageAssetDictionary {
        let delegate = self.sessionManager.delegate
        
        /// User typing indicator
        var userTypingIcon = delegate?.override(imageAsset: .chatWritingIndicator)
        if userTypingIcon == nil {
            userTypingIcon = UIImage.animatedImage(with: [Int](0...23).compactMap({
                UIImage(named: "icon_writing_\($0)", in: .SDKBundle, compatibleWith: nil)
            }), duration: 1.0)
        }
        
        /// Left side bubble
        var leftSideBubble = delegate?.override(imageAsset: .chatBubbleLeft)
        if leftSideBubble == nil {
            leftSideBubble = UIImage(named: "chat_bubble_left", in: .SDKBundle, compatibleWith: nil)
        }
        
        /// Left side bubble (series)
        var leftSideBubbleSeries = delegate?.override(imageAsset: .chatBubbleLeftRepeated)
        if leftSideBubbleSeries == nil {
            leftSideBubbleSeries = UIImage(named: "chat_bubble_left_series", in: .SDKBundle, compatibleWith: nil)
        }
        
        /// Right side bubble
        var rightSideBubble = delegate?.override(imageAsset: .chatBubbleRight)
        if rightSideBubble == nil {
            rightSideBubble = UIImage(named: "chat_bubble_right", in: .SDKBundle, compatibleWith: nil)
        }
        
        /// Left side bubble (series)
        var rightSideBubbleSeries = delegate?.override(imageAsset: .chatBubbleRightRepeated)
        if rightSideBubbleSeries == nil {
            rightSideBubbleSeries = UIImage(named: "chat_bubble_right_series", in: .SDKBundle, compatibleWith: nil)
        }
        
        /// Left side avatar
        var leftSideAvatar = delegate?.override(imageAsset: .chatAvatarLeft)
        if leftSideAvatar == nil {
            leftSideAvatar = UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)
        }
        
        /// Right side avatar
        var rightSideAvatar = delegate?.override(imageAsset: .chatAvatarRight)
        if rightSideAvatar == nil {
            rightSideAvatar = UIImage(named: "icon_avatar_mine", in: .SDKBundle, compatibleWith: nil)
        }
        
        /// Play video icon
        var playVideoIcon = delegate?.override(imageAsset: .chatPlayVideo)
        if playVideoIcon == nil {
            playVideoIcon = UIImage(named: "icon_play", in: .SDKBundle, compatibleWith: nil)
        }
        
        return [.chatWritingIndicator: userTypingIcon!,
                .chatBubbleLeft: leftSideBubble!,
                .chatBubbleLeftRepeated: leftSideBubbleSeries!,
                .chatBubbleRight: rightSideBubble!,
                .chatBubbleRightRepeated: rightSideBubbleSeries!,
                .chatAvatarLeft: leftSideAvatar!,
                .chatAvatarRight: rightSideAvatar!,
                .chatPlayVideo: playVideoIcon!]
    }
    
    var colorAssetsDictionary: [ColorConstants:UIColor] {
        let delegate = self.sessionManager.delegate
        let colorKeys: [ColorConstants] = [.infoText,
                                           .chatName,
                                           .chatTimestamp,
                                           .chatBubbleLeftText,
                                           .chatBubbleRightText,
                                           .chatBubbleLeftLink,
                                           .chatBubbleRightLink]
        
        return colorKeys.reduce(into: [:]) { (colorAsset: inout [ColorConstants:UIColor], key) in
            if let color = delegate?.override(colorAsset: key) {
                colorAsset[key] = color
            }
        }
    }
}

// MARK: - UITableViewDataSource - UITableViewDelegate

extension ChatView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.cellConstraints.insert(.zero, at: 0)
        return dataSource.numberOfMessages(for: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = dataSource.message(at: indexPath.row, self)
        
        if let channelMSG = message as? NINChannelMessage {
            return setupBubbleCell(channelMSG, at: indexPath)
        } else if let typingMSG = message as? NINUserTypingMessage {
            return setupTypingCell(typingMSG, at: indexPath)
        } else if let metaMSG = message as? NINChatMetaMessage {
            return setupMetaCell(metaMSG, at: indexPath)
        }
        fatalError("Invalid message type")
    }
}

// MARK: - Helper methods for Cell Setup

extension ChatView {
    private func setupBubbleCell(_ message: NINChannelMessage, at indexPath: IndexPath) -> ChatChannelCell {
        let cell = self.cell(message, tableView, indexPath)
        cell.session = self.sessionManager
        cell.videoThumbnailManager = videoThumbnailManager

        cell.onComposeSendTapped = { [unowned self] composeContentView in
            self.delegate?.didSendUIAction(composeContent: composeContentView)
        }
        cell.onComposeUpdateTapped = { [unowned self] composeState in
            self.composeMessageStates?[message.messageID] = composeState
        }
        cell.onImageTapped = { [unowned self] attachment, image in
            self.delegate.didSelect(image: image, for: attachment, self)
        }
        cell.onConstraintsUpdate = { [unowned self] in
            cell.isReloading = true
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }, completion: { finished in
                cell.isReloading = !finished
            })
        }
        
        cell.populateChannel(message: message, configuration: self.sessionManager.siteConfiguration, imageAssets: self.imageAssets, colorAssets: self.colorAssets, agentAvatarConfig: self.agentAvatarConfig, userAvatarConfig: self.userAvatarConfig, composeState: self.composeMessageStates?[message.messageID])
        return cell
    }

    private func setupTypingCell(_ message: NINUserTypingMessage, at indexPath: IndexPath) -> ChatTypingCell {
        let cell: ChatTypingCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.populateTyping(message: message, imageAssets: imageAssets, colorAssets: colorAssets, agentAvatarConfig: agentAvatarConfig)
        return cell
    }

    private func setupMetaCell(_ message: NINChatMetaMessage, at indexPath: IndexPath) -> ChatMetaCell {
        let cell: ChatMetaCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.delegate = self.sessionManager.delegate
        cell.onCloseChatTapped = { [unowned self] _ in
            self.delegate.didRequestToClose(self)
        }
        
        cell.populate(message: message, colorAssets: self.colorAssets)
        return cell
    }
}