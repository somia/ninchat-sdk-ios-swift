//
//  Constants.swift
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 22.11.2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

import Foundation


public typealias NINImageAssetKey = String
public enum AssetConstants: NINImageAssetKey {
    case iconLoader = "NINImageAssetKeyQueueViewProgressIndicator"
    case iconChatCloseButton = "NINImageAssetKeyIconChatCloseButton"
    case iconRatingPositive = "NINImageAssetKeyIconRatingPositive"
    case iconRatingNeutral = "NINImageAssetKeyIconRatingNeutral"
    case iconRatingNegative = "NINImageAssetKeyIconRatingNegative"
    case iconTextareaCamera = "NINImageAssetKeyIconTextareaCamera"
    case iconTextareaAttachment = "NINImageAssetKeyIconTextareaAttachment"
    case iconDownload = "NINImageAssetKeyIconDownload"
    case iconTextareaSubmitButtonIcon = "NINImageAssetKeyIconTextareaSubmitButtonIcon"
    case iconVideoToggleFull = "NINImageAssetKeyIconVideoToggleFull"
    case iconVideoToggleNormal = "NINImageAssetKeyIconVideoToggleNormal"
    case iconVideoSoundOn = "NINImageAssetKeyIconVideoSoundOn"
    case iconVideoSoundOff = "NINImageAssetKeyIconVideoSoundOff"
    case iconVideoMicrophoneOn = "NINImageAssetKeyIconVideoMicrophoneOn"
    case iconVideoMicrophoneOff = "NINImageAssetKeyIconVideoMicrophoneOff"
    case iconVideoCameraOn = "NINImageAssetKeyIconVideoCameraOn"
    case iconVideoCameraOff = "NINImageAssetKeyIconVideoCameraOff"
    case iconVideoHangup = "NINImageAssetKeyIconVideoHangup"

    case chatWritingIndicator = "NINImageAssetKeyChatWritingIndicator"
    case chatBackground = "NINImageAssetKeyChatBackground"
    case chatCloseButton = "NINImageAssetKeyChatCloseButton"
    case chatBubbleLeft = "NINImageAssetKeyChatBubbleLeft"
    case chatBubbleLeftRepeated = "NINImageAssetKeyChatBubbleLeftRepeated"
    case chatBubbleRight = "NINImageAssetKeyChatBubbleRight"
    case chatBubbleRightRepeated = "NINImageAssetKeyChatBubbleRightRepeated"
    case chatAvatarRight = "NINImageAssetKeyChatAvatarRight"
    case chatAvatarLeft = "NINImageAssetKeyChatAvatarLeft"
    case chatPlayVideo = "NINImageAssetKeyChatPlayVideo"
    
    case textareaSubmitButton = "NINImageAssetKeyTextareaSubmitButton"
    case primaryButton = "NINImageAssetKeyPrimaryButton"
    case secondaryButton = "NINImageAssetKeySecondaryButton"
}

public typealias NINColorAssetKey = String
public enum ColorConstants: NINColorAssetKey {
    case buttonPrimaryText = "NINColorAssetKeyButtonPrimaryText"
    case buttonSecondaryText = "NINColorAssetKeyButtonSecondaryText"
    case infoText = "NINColorAssetKeyInfoText"
    case chatName = "NINColorAssetKeyChatName"
    case chatTimestamp = "NINColorAssetKeyChatTimestamp"
    case chatBubbleLeftText = "NINColorAssetKeyChatBubbleLeftText"
    case chatBubbleRightText = "NINColorAssetKeyChatBubbleRightText"
    case textareaText = "NINColorAssetKeyTextareaText"
    case textareaSubmitText = "NINColorAssetKeyTextareaSubmitText"
    case chatBubbleLeftLink = "NINColorAssetKeyChatBubbleLeftLink"
    case chatBubbleRightLink = "NINColorAssetKeyChatBubbleRightLink"
    case modalText = "NINColorAssetKeyModalText"
    case modalBackground = "NINColorAssetKeyModalBackground"
    case backgroundTop = "NINColorAssetBackgroundTop"
    case textTop = "NINColorAssetTextTop"
    case textBottom = "NINColorAssetTextBottom"
    case link = "NINColorAssetLink"
    case backgroundBottom = "NINColorAssetBackgroundBottom"
    case ratingPositiveText = "NINColorAssetRatingPositiveText"
    case ratingNeutralText = "NINColorAssetRatingNeutralText"
    case ratingNegativeText = "NINColorAssetRatingNegativeText"
}

public enum Constants: String {
    case kTestServerAddress = "api.luupi.net"
    case kProductionServerAddress = "api.ninchat.com"
    
    case kCloseWindowText = "Close window"
    case kJoinQueueText = "Join audience queue {{audienceQueue.queue_attrs.name}}"
    case kQueuePositionN = "Joined audience queue {{audienceQueue.queue_attrs.name}}, you are at position {{audienceQueue.queue_position}}."
    case kQueuePositionNext = "Joined audience queue {{audienceQueue.queue_attrs.name}}, you are next."
    case kCloseChatText = "Close chat"
}
