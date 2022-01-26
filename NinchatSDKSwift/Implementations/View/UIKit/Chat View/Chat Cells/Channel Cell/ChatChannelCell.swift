//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class ChatChannelCell: UITableViewCell, ChatCell, ChannelCell {
    
    internal var message: ChannelMessage?
    
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

    weak var session: NINChatSessionAttachment?
    var videoThumbnailManager: VideoThumbnailManager?
    var onImageTapped: ((FileInfo, UIImage?) -> Void)?
    var onComposeSendTapped: ComposeMessageViewProtocol.OnUIComposeSendActionTapped?
    var onComposeUpdateTapped: ComposeMessageViewProtocol.OnUIComposeUpdateActionTapped?

    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        /// Rotate the cell 180 degrees; we will use the table view upside down
        self.rotate()
        
        /// The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
        self.rasterize()
    }
    
    // MARK: - ChannelCell
    
    var delegate: NINChatSessionInternalDelegate?
    
    func populateChannel(message: ChannelMessage, configuration: SiteConfiguration?, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, agentAvatarConfig: AvatarConfig?, userAvatarConfig: AvatarConfig?, composeState: [Bool]?) {
        self.message = message

        if let sender = message.sender, !sender.displayName.isEmpty {
            self.senderNameLabel.text = sender.displayName
        } else {
            self.senderNameLabel.text = "Guest".localized
        }
        self.timeLabel.text = DateFormatter.shortTime.string(from: message.timestamp)
        self.infoContainerView.height?.constant = (message.series) ? 0 : 40 /// Hide the name and timestamp if it's a part of series message chain
        self.infoContainerView.height?.priority = .required
        self.infoContainerView.allSubviews.forEach { $0.isHidden = message.series }
    
        if let cell = self as? ChannelTextCell, let textMessage = message as? TextMessage {
            cell.populateText(message: textMessage, attachment: textMessage.attachment)
        } else if let cell = self as? ChannelMediaCell, let textMessage = message as? TextMessage {
            cell.populateText(message: textMessage, attachment: textMessage.attachment)
        } else if let cell = self as? ChatChannelComposeCell, let uiComposeMessage = message as? ComposeMessage {
            cell.delegate = self.delegate
            cell.populateCompose(message: uiComposeMessage, configuration: configuration, colorAssets: colorAssets, composeStates: composeState)
        }
    }
    
    /// Performs asset customizations independent of message sender
    internal func applyCommon(imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?) {
        if let nameColor = colorAssets?[.ninchatColorChatName] {
            self.senderNameLabel.textColor = nameColor
        }
        
        if let timeColor = colorAssets?[.ninchatColorChatTimestamp] {
            self.timeLabel.textColor = timeColor
        }
    }

    internal func apply(avatar config: AvatarConfig?, imageView: UIImageView, url: String?, overrideWith override: UIImage) {
        imageView.isHidden = !(config?.show ?? false)
        if let overrideURL = config?.imageOverrideURL {
            imageView.image(from: overrideURL, defaultImage: override)
        } else if let url = url, !url.isEmpty {
            imageView.image(from: url, defaultImage: override)
        } else {
            imageView.image = override
        }
    }
}

extension ChatChannelCell: UITextViewDelegate {
    @available(iOS 10.0, *)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { true }
    
    @available(iOS, deprecated: 10.0)
    @objc public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool { true }
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
    
    override func populateChannel(message: ChannelMessage, configuration: SiteConfiguration?, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, agentAvatarConfig: AvatarConfig?, userAvatarConfig: AvatarConfig?, composeState: [Bool]?) {
        super.populateChannel(message: message, configuration: configuration, imageAssets: imageAssets, colorAssets: colorAssets, agentAvatarConfig: agentAvatarConfig, userAvatarConfig: userAvatarConfig, composeState: composeState)
        self.configureMyMessage(avatar: message.sender?.iconURL, imageAssets: imageAssets, colorAssets: colorAssets, config: userAvatarConfig, series: message.series)
    }
    
    internal func configureMyMessage(avatar url: String?, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, config: AvatarConfig?, series: Bool) {
        self.senderNameLabel.textAlignment = .right
        self.bubbleImageView.image = UIImage(named: (series) ? "chat_bubble_right_series" : "chat_bubble_right", in: .SDKBundle, compatibleWith: nil)
        
        /// White text on black bubble
        self.bubbleImageView.tintColor = colorAssets?[.ninchatColorChatBubbleRightTint] ?? .black
        if let name = config?.nameOverride, !name.isEmpty {
            self.senderNameLabel.text = name
        }

        /// Apply asset overrides
        self.applyCommon(imageAssets: imageAssets, colorAssets: colorAssets)
        self.apply(avatar: config, imageView: self.rightAvatarImageView, url: url, overrideWith: imageAssets?[.ninchatChatAvatarRight] ?? UIImage(named: "icon_avatar_mine", in: .SDKBundle, compatibleWith: nil)!)
        
        /// Push the top label container to the left edge by toggling the constraints
        self.toggleBubbleConstraints(isMyMessage: true, isSeries: series, showByConfig: config?.show ?? false)
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

    override func populateChannel(message: ChannelMessage, configuration: SiteConfiguration?, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, agentAvatarConfig: AvatarConfig?, userAvatarConfig: AvatarConfig?, composeState: [Bool]?) {
        super.populateChannel(message: message, configuration: configuration, imageAssets: imageAssets, colorAssets: colorAssets, agentAvatarConfig: agentAvatarConfig, userAvatarConfig: userAvatarConfig, composeState: composeState)
        self.configureOtherMessage(avatar: message.sender?.iconURL, imageAssets: imageAssets, colorAssets: colorAssets, config: agentAvatarConfig, series: message.series)
    }
    
    internal func configureOtherMessage(avatar url: String?, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, config: AvatarConfig?, series: Bool) {
        self.senderNameLabel.textAlignment = .left
        self.bubbleImageView.image = UIImage(named: (series) ? "chat_bubble_left_series" : "chat_bubble_left", in: .SDKBundle, compatibleWith: nil)
        
        /// Black text on white bubble
        self.bubbleImageView.tintColor = colorAssets?[.ninchatColorChatBubbleLeftTint] ?? .white
        if let name = config?.nameOverride, !name.isEmpty {
            self.senderNameLabel.text = name
        }
        
        /// Apply asset overrides
        self.applyCommon(imageAssets: imageAssets, colorAssets: colorAssets)
        self.apply(avatar: config, imageView: self.leftAvatarImageView, url: url, overrideWith: imageAssets?[.ninchatChatAvatarLeft] ?? UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)!)
        
        /// Push the top label container to the left edge by toggling the hidden flag
        self.toggleBubbleConstraints(isMyMessage: false, isSeries: series, showByConfig: config?.show ?? false)
    }
    
    private func toggleBubbleConstraints(isMyMessage: Bool, isSeries: Bool, showByConfig: Bool) {
        self.leftAvatarImageView?.isHidden = isMyMessage ? true : (isSeries || !showByConfig)
        self.leftAvatarContainer?.width?.constant = (!isMyMessage && showByConfig) ? 35 : 0
    }
}
