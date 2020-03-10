//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

class ChatChannelCell: UITableViewCell, ChatCell, ChannelCell {
    
    internal var message: NINChannelMessage?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var infoContainerView: UIView!
    @IBOutlet private(set) weak var bubbleImageView: UIImageView!
    @IBOutlet private(set) weak var senderNameLabel: UILabel! {
        didSet {
            senderNameLabel.font = .ninchat
        }
    }
    @IBOutlet private(set) weak var timeLabel: UILabel! {
        didSet {
            timeLabel.font = .ninchat
        }
    }
    
    // MARK: - ChatCell
    var isReloading: Bool! = false
    
    var session: NINChatSessionAttachment!
    var videoThumbnailManager: NINVideoThumbnailManager?
    var onImageTapped: ((NINFileInfo, UIImage?) -> Void)?
    var onComposeSendTapped: ((NINComposeContentView) -> Void)?
    var onComposeUpdateTapped: (([Any]?) -> Void)?
    var onConstraintsUpdate: (() -> Void)?
        
    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        /// Rotate the cell 180 degrees; we will use the table view upside down
        self.rotate()
        
        /// The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
        self.rasterize()
    }
    
    // MARK: - ChannelCell
    
    func populateChannel(message: NINChannelMessage, configuration: NINSiteConfiguration, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, agentAvatarConfig: NINAvatarConfig, userAvatarConfig: NINAvatarConfig, composeState: [Any]?) {
        self.message = message
        
        self.senderNameLabel.text = (message.sender.displayName.count < 1) ? "Guest" : message.sender.displayName
        self.timeLabel.text = DateFormatter.shortTime.string(from: message.timestamp)
        self.infoContainerView.height?.constant = (message.series) ? 0 : 40 /// Hide the name and timestamp if it's a part of series message chain
        self.infoContainerView.height?.priority = .defaultHigh
        self.infoContainerView.allSubviews.forEach {
            $0.isHidden = message.series
        }
    
        if let cell = self as? ChannelTextCell, let textMessage = message as? NINTextMessage {
            cell.populateText(message: textMessage, attachment: textMessage.attachment)
        } else if let cell = self as? ChannelMediaCell, let textMessage = message as? NINTextMessage {
            cell.populateText(message: textMessage, attachment: textMessage.attachment)
        } else if let cell = self as? ChatChannelComposeCell, let uiComposeMessage = message as? NINUIComposeMessage {
            cell.composeMessageView.clear()
            cell.populateCompose(message: uiComposeMessage, configuration: configuration, colorAssets: colorAssets, composeStates: composeState)
        }
    }
    
    /// Performs asset customizations independent of message sender
    internal func applyCommon(imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary) {
        if let nameColor = colorAssets[.chatName] {
            self.senderNameLabel.textColor = nameColor
        }
        
        if let timeColor = colorAssets[.chatTimestamp] {
            self.timeLabel.textColor = timeColor
        }
    }
    
    internal func apply(avatar config: NINAvatarConfig, imageView: UIImageView) {
        imageView.isHidden = !config.show
        if !config.imageOverrideUrl.isEmpty {
            imageView.setImageURL(config.imageOverrideUrl)
        }
    }
}

extension ChatChannelCell: UITextViewDelegate {
    @available(iOS 10.0, *)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
    
    @available(iOS, deprecated: 10.0)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}

class ChatChannelMineCell: ChatChannelCell {
    @IBOutlet private(set) weak var rightAvatarContainer: UIView!
    @IBOutlet private(set) weak var rightAvatarImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.rightAvatarImageView.round()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.bubbleImageView.height?.isActive = false
        self.bubbleImageView.width?.isActive = false
    }
    
    override func populateChannel(message: NINChannelMessage, configuration: NINSiteConfiguration, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, agentAvatarConfig: NINAvatarConfig, userAvatarConfig: NINAvatarConfig, composeState: [Any]?) {
        super.populateChannel(message: message, configuration: configuration, imageAssets: imageAssets, colorAssets: colorAssets, agentAvatarConfig: agentAvatarConfig, userAvatarConfig: userAvatarConfig, composeState: composeState)
        self.configureMyMessage(avatar: message.sender.iconURL, imageAssets: imageAssets, colorAssets: colorAssets, config: userAvatarConfig, series: message.series)
    }
    
    internal func configureMyMessage(avatar url: String, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, config: NINAvatarConfig, series: Bool) {
        self.senderNameLabel.textAlignment = .right
        self.bubbleImageView.image = (series) ? imageAssets[.chatBubbleRightRepeated] : imageAssets[.chatBubbleRight]
        
        /// White text on black bubble
        self.bubbleImageView.tintColor = .black
        if !config.nameOverride.isEmpty {
            self.senderNameLabel.text = config.nameOverride
        }
        
        /// Apply asset overrides
        self.applyCommon(imageAssets: imageAssets, colorAssets: colorAssets)
        self.apply(avatar: config, imageView: self.rightAvatarImageView)
        
        /// Push the top label container to the left edge by toggling the constraints
        self.toggleBubbleConstraints(isMyMessage: true, isSeries: series, showByConfig: config.show)
    }
    
    private func toggleBubbleConstraints(isMyMessage: Bool, isSeries: Bool, showByConfig: Bool) {
        self.rightAvatarImageView.isHidden = isMyMessage ? (isSeries || !showByConfig) : true
        self.rightAvatarContainer.width?.constant = (isMyMessage && showByConfig) ? 35 : 0
    }
}

class ChatChannelOthersCell: ChatChannelCell {
    @IBOutlet private(set) weak var leftAvatarContainer: UIView!
    @IBOutlet private(set) weak var leftAvatarImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.leftAvatarImageView.round()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.bubbleImageView.height?.isActive = false
        self.bubbleImageView.width?.isActive = false
    }
    
    override func populateChannel(message: NINChannelMessage, configuration: NINSiteConfiguration, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, agentAvatarConfig: NINAvatarConfig, userAvatarConfig: NINAvatarConfig, composeState: [Any]?) {
        super.populateChannel(message: message, configuration: configuration, imageAssets: imageAssets, colorAssets: colorAssets, agentAvatarConfig: agentAvatarConfig, userAvatarConfig: userAvatarConfig, composeState: composeState)
        self.configureOtherMessage(avatar: message.sender.iconURL, imageAssets: imageAssets, colorAssets: colorAssets, config: agentAvatarConfig, series: message.series)
    }
    
    internal func configureOtherMessage(avatar url: String, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, config: NINAvatarConfig, series: Bool) {
        self.senderNameLabel.textAlignment = .left
        self.bubbleImageView.image = (series) ? imageAssets[.chatBubbleLeftRepeated] : imageAssets[.chatBubbleLeft]
        
        /// Black text on white bubble
        self.bubbleImageView.tintColor = .white
        if !config.nameOverride.isEmpty {
            self.senderNameLabel.text = config.nameOverride
        }
        
        /// Apply asset overrides
        self.applyCommon(imageAssets: imageAssets, colorAssets: colorAssets)
        self.apply(avatar: config, imageView: self.leftAvatarImageView)
        
        /// Push the top label container to the left edge by toggling the hidden flag
        self.toggleBubbleConstraints(isMyMessage: false, isSeries: series, showByConfig: config.show)
    }
    
    private func toggleBubbleConstraints(isMyMessage: Bool, isSeries: Bool, showByConfig: Bool) {
        self.leftAvatarImageView?.isHidden = isMyMessage ? true : (isSeries || !showByConfig)
        self.leftAvatarContainer?.width?.constant = (!isMyMessage && showByConfig) ? 35 : 0
    }
}