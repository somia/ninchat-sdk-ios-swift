//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

final class ChatChannelCell: UITableViewCell, ChatCell {
    
    private var avatarContainerWidth: CGFloat!
    private var topLabelsContainerHeight: CGFloat!
    private var message: NINChannelMessage?
    
    // MARK: - Outlets

    @IBOutlet private weak var mainContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerRightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var infoContainerView: UIView!
    @IBOutlet private weak var infoContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var infoContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var infoContainerRightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var bubbleImageView: UIImageView!
    @IBOutlet private weak var bubbleImageLeftGreaterConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleImageLeftEqualConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleImageRightGreaterConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleImageRightEqualConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var leftAvatarImageView: UIImageView!
    @IBOutlet private weak var rightAvatarImageView: UIImageView!
    
    @IBOutlet private weak var messageTextView: UITextView! {
        didSet {
            messageTextView.delegate = self
        }
    }
    
    @IBOutlet private weak var messageImageViewContainer: UIView!
    @IBOutlet private weak var messageImageView: UIImageView!
    
    @IBOutlet private weak var videoPlayerContainer: UIView!
    @IBOutlet private weak var videoPlayImageView: UIImageView!
    
    @IBOutlet private weak var composeMessageView: NINComposeMessageView!
    
    @IBOutlet private weak var senderNameLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
        
    // MARK: - ChatCell
    
    var session: NINChatSessionAttachment!
    var videoThumbnailManager: NINVideoThumbnailManager?
    var onImageTapped: ((NINFileInfo, UIImage?) -> Void)?
    var onComposeSendTapped: ((NINComposeContentView) -> Void)? {
        set {
            self.composeMessageView.uiComposeSendPressedCallback = { compose in
                newValue?(compose!)
            }
        }
        get {
            return self.composeMessageView.uiComposeSendPressedCallback
        }
    }
    var onComposeUpdateTapped: (([Any]?) -> Void)?
    var onConstraintsUpdate: (() -> Void)?
    
    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        /// Make the avatar image views circles
        self.leftAvatarImageView.round()
        self.rightAvatarImageView.round()
        
        /// Workaround for https://openradar.appspot.com/18448072
        let img = self.videoPlayImageView.image
        self.videoPlayImageView.image = nil
        self.videoPlayImageView.image = img
        
        /// Rotate the cell 180 degrees; we will use the table view upside down
        self.rotate()
        
        /// The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
        self.rasterize()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.onConstraintsUpdate = nil
        self.onImageTapped = nil
        self.onComposeSendTapped = nil
    }
}

extension ChatChannelCell: ChannelCell {
    func populateChannel(message: NINChannelMessage, configuration: NINSiteConfiguration, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, agentAvatarConfig: NINAvatarConfig, userAvatarConfig: NINAvatarConfig, composeState: [Any]?) {
        self.message = message
        
        /// TODO: Porbably needs localized string
        self.senderNameLabel.text = (message.sender.displayName.count < 1) ? "Guest" : message.sender.displayName
        self.timeLabel.text = DateFormatter.shortTime()?.string(from: message.timestamp) ?? ""
        /// Hide the name and timestamp if it's a part of series message chain
        self.infoContainerHeightConstraint.constant = (message.series) ? 0 : 40
                
        /// Make Image view background match the bubble color
        self.messageImageView.backgroundColor = self.bubbleImageView.tintColor
        
        if let textMessage = message as? NINTextMessage {
            self.populateText(message: textMessage, attachment: textMessage.attachment)
        } else if let uiComposeMessage = message as? NINUIComposeMessage {
            self.populateCompose(message: uiComposeMessage, configuration: configuration, colorAssets: colorAssets, composeStates: composeState)
        }
        
        if message.mine {
            /// Visitor's (= phone user) message - on the right
            self.configureMyMessage(avatar: message.sender.iconURL, imageAssets: imageAssets, colorAssets: colorAssets, config: userAvatarConfig, series: message.series)
            if !userAvatarConfig.nameOverride.isEmpty {
                self.senderNameLabel.text = userAvatarConfig.nameOverride
            }
        } else {
            /// Other's message - on the left
            self.configureOtherMessage(avatar: message.sender.iconURL, imageAssets: imageAssets, colorAssets: colorAssets, config: agentAvatarConfig, series: message.series)
            if !agentAvatarConfig.nameOverride.isEmpty {
                self.senderNameLabel.text = agentAvatarConfig.nameOverride
            }
        }
    }
}

extension ChatChannelCell: TypingCell {
    func populateTyping(message: NINUserTypingMessage, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, agentAvatarConfig: NINAvatarConfig) {
        self.messageTextView.isHidden = false
        self.messageImageViewContainer.isHidden = false
        self.videoPlayerContainer.isHidden = true
        self.composeMessageView.isHidden = true
        
        self.senderNameLabel.text = (agentAvatarConfig.nameOverride.isEmpty) ? message.user.displayName : agentAvatarConfig.nameOverride
        self.messageTextView.text = ""
        
        self.configureOtherMessage(avatar: message.user.iconURL, imageAssets: imageAssets, colorAssets: colorAssets, config: agentAvatarConfig, series: false)
        
        /// Make Image view background match the bubble color
        self.messageImageView.backgroundColor = self.bubbleImageView.tintColor
        self.messageImageView.image = imageAssets[.chatWritingIndicator]
        self.messageImageView.tintColor = .black
        
        /// Set the image aspect ratio to match the animation frames' size 40x20
        self.setImage(aspect: 0.5)
    }
}

// MARK: - Helper methods

extension ChatChannelCell {
    @objc
    private func didTappedOnImage() {
        guard let message = self.message as? NINTextMessage, let attachment = message.attachment else { return }
        
        if attachment.isVideo {
            /// Will open video player
            self.onImageTapped?(attachment, nil)
        } else if attachment.isImage, let image = self.messageImageView.image {
            /// Will show full-screen image viewer
            self.onImageTapped?(attachment, image)
        }
    }
    
    private func setImage(aspect ratio: CGFloat) {
        let width = self.contentView.bounds.width/2
        self.bubbleImageView.deactivate(size: [.width, .height])
        self.bubbleImageView.fix(width: width, height: width * ratio)
    }
    
    private func resetImageLayout() {
        self.messageImageView.image = nil
        self.messageImageViewContainer.gestureRecognizers?.forEach { self.messageImageViewContainer.removeGestureRecognizer($0) }
        self.videoPlayerContainer.gestureRecognizers?.forEach { self.videoPlayerContainer.removeGestureRecognizer($0) }
    }
    
    private func toggleBubbleConstraints(isMyMessage: Bool, isSeries: Bool) {
        self.leftAvatarImageView.isHidden = isMyMessage ? true : isSeries
        self.rightAvatarImageView.isHidden = isMyMessage ? isSeries : true
        
        self.bubbleImageLeftEqualConstraint.isActive = !isMyMessage
        self.bubbleImageLeftGreaterConstraint.isActive = isMyMessage
        
        self.bubbleImageRightEqualConstraint.isActive = isMyMessage
        self.bubbleImageRightGreaterConstraint.isActive = !isMyMessage
        
        self.infoContainerLeftConstraint.isActive = !isMyMessage
        self.infoContainerRightConstraint.isActive = isMyMessage
    }
}

// MARK: - Cell configurations

extension ChatChannelCell {
    /// Configures the cell to be "on the right"
    private func configureMyMessage(avatar url: String, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, config: NINAvatarConfig, series: Bool) {
        
        self.messageTextView.textAlignment = .right
        self.bubbleImageView.image = (series) ? imageAssets[.chatBubbleRightRepeated] : imageAssets[.chatBubbleRight]
        
        /// White text on black bubble
        self.bubbleImageView.tintColor = .black
        self.messageTextView.textColor = .white
        
        /// Push the bubble to the right edge by setting the left and right constraints
        self.mainContainerLeftConstraint.constant = 20
        self.mainContainerRightConstraint.constant = 0
                
        /// Apply asset overrides
        self.applyCommon(imageAssets: imageAssets, colorAssets: colorAssets)
        self.apply(avatar: config, imageView: self.rightAvatarImageView)
        
        /// Push the top label container to the left edge by toggling the constraints
        self.toggleBubbleConstraints(isMyMessage: true, isSeries: series)
        
        if let bubbleTextColor = colorAssets[.chatBubbleRightText] {
            self.messageTextView.textColor = bubbleTextColor
        }
        if let linkColor = colorAssets[.chatBubbleRightLink] {
            self.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
        }
    }
    
    /// Configures the cell to be "on the left"
    private func configureOtherMessage(avatar url: String, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, config: NINAvatarConfig, series: Bool) {
        
        self.messageTextView.textAlignment = .left
        self.bubbleImageView.image = (series) ? imageAssets[.chatBubbleLeftRepeated] : imageAssets[.chatBubbleLeft]
    
        /// Black text on white bubble
        self.bubbleImageView.tintColor = .white
        self.messageTextView.textColor = .black
        self.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        
        /// Push the bubble to the left edge by setting the right and left constraints
        self.mainContainerLeftConstraint.constant = 0
        self.mainContainerRightConstraint.constant = 20
        
        /// Apply asset overrides
        self.applyCommon(imageAssets: imageAssets, colorAssets: colorAssets)
        self.apply(avatar: config, imageView: self.leftAvatarImageView)
        
        /// Push the top label container to the left edge by toggling the hidden flag
        self.toggleBubbleConstraints(isMyMessage: false, isSeries: series)
        
        if let bubbleTextColor = colorAssets[.chatBubbleLeftText] {
            self.messageTextView.textColor = bubbleTextColor
        }
        if let linkColor = colorAssets[.chatBubbleLeftLink] {
            self.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
        }
    }
    
    /// Performs asset customizations indenpendent of message sender
    private func applyCommon(imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary) {
        if let nameColor = colorAssets[.chatName] {
            self.senderNameLabel.textColor = nameColor
        }
    
        if let timeColor = colorAssets[.chatTimestamp] {
            self.timeLabel.textColor = timeColor
        }
        
        self.videoPlayImageView.image = imageAssets[.chatPlayVideo]
    }
    
    /// Returns YES if the default avatar image should be applied afterwards
    private func apply(avatar config: NINAvatarConfig, imageView: UIImageView) {
        imageView.isHidden = !config.show
        if !config.imageOverrideUrl.isEmpty {
            imageView.setImageURL(config.imageOverrideUrl)
        }
    }
    
    /// Update constraints to match new thumbnail image size
    private func updateVideo(thumbnail: UIImage, fromCache: Bool) {
        self.setImage(aspect: thumbnail.size.height / thumbnail.size.width)
        self.messageImageView.image = thumbnail
                
        if !fromCache {
            /// Animate the thumbnail in
            self.messageImageViewContainer.alpha = 0
            self.messageImageViewContainer.hide = false
        }
        
        /// Inform the chat view that our cell might need resizing due to new constraints.
        /// We do this regardless of fromCache -value as this method may have been called asynchronously
        /// from `updateInfo(session:completion:)` completion block in populate method.
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
        self.onConstraintsUpdate?()
    }
    
    /// asynchronous = YES implies we're calling this asynchronously from the
    /// `updateInfo(session:completion:)` completion block (meaning it did a network update)
    private func updateImage(asynchronous: Bool) throws {
        guard let message = self.message as? NINTextMessage else { throw NINUIExceptions.noMessage }
        guard let attachment = message.attachment else { throw NINUIExceptions.noAttachment }
        guard attachment.isVideo || attachment.isImage else { throw NINUIExceptions.invalidAttachment }
        
        self.messageImageViewContainer.isHidden = !attachment.isImage && !attachment.isVideo
        self.videoPlayerContainer.isHidden = !attachment.isVideo
        self.composeMessageView.isHidden = true
        self.messageTextView.isHidden = true
                
        /// Make sure we have an image tap recognizer in place
        self.resetImageLayout()
        self.messageImageViewContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
        self.videoPlayerContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
        
        /// Set message image's aspect ratio<
        if let ratio = attachment.aspectRatio, ratio > 0 {
            self.setImage(aspect: CGFloat(ratio))
        }
        
        if attachment.isImage, let imageURL = attachment.url {
            /// Load the image in message image view over HTTP or from local cache
            self.messageImageView.setImageURL(imageURL)
            
            guard asynchronous else { return }
            /// Inform the chat view that our cell might need resizing due to new constraints.
            self.contentView.setNeedsLayout()
            self.contentView.layoutIfNeeded()
            self.onConstraintsUpdate?()
        } else if attachment.isVideo, let videoURL = attachment.url {
            guard let thumbnailManager = self.videoThumbnailManager else { throw NINUIExceptions.noThumbnailManager }
            
            /// For video we must fetch the thumbnail image
            thumbnailManager.getVideoThumbnail(videoURL) { [unowned self] error, fromCache, thumbnail in
                guard let image = thumbnail, error == nil else {
                    /// TODO: localize error msg
                    NINToast.showWithErrorMessage("Failed to get video thumbnail", callback: nil); return
                }
                self.updateVideo(thumbnail: image, fromCache: fromCache)
            }
        }
    }
}

// MARK: - Cell population

extension ChatChannelCell {
    private func populateText(message: NINTextMessage, attachment: NINFileInfo?) {
        /// The attachment for a text message is not implemented
        /// Thus, the function is only tested through possible scenarios
        /// TODO: More tests once the attachment is implemented on the panel.
        
        self.resetImageLayout()
        self.composeMessageView.isHidden = true
        self.messageImageViewContainer.isHidden = !(attachment?.isImage ?? false) || attachment?.isPDF ?? true
        self.videoPlayerContainer.isHidden = !(attachment?.isVideo ?? false) || attachment?.isPDF ?? true
        
        if attachment?.isPDF ?? false, let url = attachment?.url, let name = attachment?.name {
            self.messageTextView.setFormattedText("<a href=\"\(url)\">\(name)</a>")
            self.messageTextView.isHidden = false
        } else {
            self.messageTextView.text = message.textContent ?? ""
            self.messageTextView.isHidden = (message.textContent?.isEmpty ?? true)
        }
        
        /// Update the message image, if any
        if let attachment = attachment, attachment.isImage || attachment.isVideo {
            attachment.updateInfo(session: self.session) { [unowned self] _, didRefreshNetwork in
                do {
                    try self.updateImage(asynchronous: didRefreshNetwork)
                } catch {
                    debugger("Error in updating attachment info: \(error)")
                }

            }
        } else {
            /// No image; clear image constraints etc so it wont affect layout
            self.resetImageLayout()
        }
    }
    
    private func populateCompose(message: NINUIComposeMessage, configuration: NINSiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Any]?) {
        
        self.resetImageLayout()
        self.messageTextView.isHidden = true
        self.messageImageViewContainer.isHidden = true
        self.videoPlayerContainer.isHidden = true
        self.composeMessageView.isHidden = false
        
        self.composeMessageView.populate(with: message, siteConfiguration: configuration, colorAssets: Dictionary(uniqueKeysWithValues: colorAssets.map { ($0.key.rawValue, $0.value) } ), composeState: composeStates)
        self.composeMessageView.uiComposeStateUpdateCallback = { [weak self] composeStates in
            self?.onComposeUpdateTapped?(composeStates)
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
