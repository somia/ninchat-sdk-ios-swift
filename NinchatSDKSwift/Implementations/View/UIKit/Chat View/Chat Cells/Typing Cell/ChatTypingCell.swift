//
// Copyright (c) 28.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

final class ChatTypingCell: UITableViewCell, TypingCell {
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var senderNameLabel: UILabel!
    @IBOutlet private(set) weak var timeLabel: UILabel!
    @IBOutlet private(set) weak var bubbleImageView: UIImageView!
    @IBOutlet private(set) weak var leftAvatarImageView: UIImageView!
    @IBOutlet private(set) weak var messageImageView: UIImageView!
    
    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        /// Make the avatar image views circles
        self.leftAvatarImageView.round()
        
        /// Rotate the cell 180 degrees; we will use the table view upside down
        self.rotate()
        
        /// The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
        self.rasterize()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.messageImageView.image = nil
    }
    
    // MARK: - TypingCell
    
    func populateTyping(message: NINUserTypingMessage, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, agentAvatarConfig: AvatarConfig) {
        self.senderNameLabel.text = (agentAvatarConfig.nameOverride.isEmpty) ? message.user.displayName : agentAvatarConfig.nameOverride
        self.timeLabel.text = DateFormatter.shortTime.string(from: message.timestamp)
    
        /// Make Image view background match the bubble color
        self.bubbleImageView.tintColor = .white
        self.bubbleImageView.image = imageAssets[.chatBubbleLeft]
        
        self.messageImageView.backgroundColor = .white
        self.messageImageView.image = imageAssets[.chatWritingIndicator]
        self.messageImageView.tintColor = .black
    
        /// Apply asset overrides
        self.applyCommon(imageAssets: imageAssets, colorAssets: colorAssets)
        self.apply(avatar: agentAvatarConfig, imageView: self.leftAvatarImageView)
    }
    
    /// Performs asset customizations independent of message sender
    private func applyCommon(imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary) {
        if let nameColor = colorAssets[.chatName] {
            self.senderNameLabel.textColor = nameColor
        }
        
        if let timeColor = colorAssets[.chatTimestamp] {
            self.timeLabel.textColor = timeColor
        }
    }
    
    /// Returns YES if the default avatar image should be applied afterwards
    private func apply(avatar config: AvatarConfig, imageView: UIImageView) {
        imageView.isHidden = !config.show
        if let overrideURL = config.imageOverrideURL {
            imageView.image(from: overrideURL)
        }
    }
}