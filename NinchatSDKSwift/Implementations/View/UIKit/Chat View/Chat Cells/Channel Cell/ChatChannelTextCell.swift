//
// Copyright (c) 29.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

protocol ChannelTextCell {
    /// Outlets
    var messageTextView: UITextView! { get set }
    
    func populateText(message: NINTextMessage, attachment: NINFileInfo?)
}

extension ChannelTextCell {
    func populateText(message: NINTextMessage, attachment: NINFileInfo?) {
        self.messageTextView.contentInset = (message.series) ? UIEdgeInsets(top: 3.5, left: 0.0, bottom: 0.0, right: 0.0) : .zero
        if attachment?.isPDF ?? false, let url = attachment?.url, let name = attachment?.name {
            self.messageTextView.setFormattedText("<a href=\"\(url)\">\(name)</a>")
        } else if let text = message.textContent {
            /// remove attributed texts if any
            self.messageTextView.setPlain(text: text, font: .ninchat, color: self.messageTextView.textColor)
        }
    }
}

final class ChatChannelTextMineCell: ChatChannelMineCell, ChannelTextCell {
    @IBOutlet weak var messageTextView: UITextView! {
        didSet {
            messageTextView.delegate = self
            messageTextView.isSelectable = true
        }
    }
    
    override func configureMyMessage(avatar url: String, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, config: NINAvatarConfig, series: Bool) {
        super.configureMyMessage(avatar: url, imageAssets: imageAssets, colorAssets: colorAssets, config: config, series: series)
    
        self.messageTextView.textColor = .white
        self.messageTextView.textAlignment = .right
        self.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        if let bubbleTextColor = colorAssets[.chatBubbleRightText] {
            self.messageTextView.textColor = bubbleTextColor
        }
        if let linkColor = colorAssets[.chatBubbleRightLink] {
            self.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
        }
        
    }
}

final class ChatChannelTextOthersCell: ChatChannelOthersCell, ChannelTextCell {
    @IBOutlet weak var messageTextView: UITextView! {
        didSet {
            messageTextView.delegate = self
            messageTextView.isSelectable = true
        }
    }
    
    override func configureOtherMessage(avatar url: String, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, config: NINAvatarConfig, series: Bool) {
        super.configureOtherMessage(avatar: url, imageAssets: imageAssets, colorAssets: colorAssets, config: config, series: series)
    
        self.messageTextView.textAlignment = .left
        self.messageTextView.textColor = .black
        self.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        if let bubbleTextColor = colorAssets[.chatBubbleLeftText] {
            self.messageTextView.textColor = bubbleTextColor
        }
        if let linkColor = colorAssets[.chatBubbleLeftLink] {
            self.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
        }
    }
}