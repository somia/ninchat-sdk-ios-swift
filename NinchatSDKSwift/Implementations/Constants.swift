//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import UIKit

public typealias NINImageAssetDictionary = [AssetConstants:UIImage]
public enum AssetConstants: String {
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

public typealias NINColorAssetDictionary = [ColorConstants:UIColor]
public enum ColorConstants: String {
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
    case kCancelDialog = "Continue chat"
    case kAcceptDialog = "Accept"
    case kRejectDialog = "Decline"
    case kTextInputPlaceholderText = "Enter your message"
    case kCallInvitationText = "You are invited to a video chat"
    case kCallInvitationInfoText = "wants to video chat with you"
    case kRatingTitleText = "How was our customer service?"
    case kRatingSkipText = "Skip"
    
    case kRatingPositiveText = "Good"
    case kRatingNeutralText = "Okay"
    case kRatingNegativeText = "Poor"
    
    case RTCSessionDescriptionType = "type"
    case RTCSessionDescriptionSDP = "sdp"
    case RTCIceCandidateKeyCandidate = "candidate"
    case RTCIceCandidateSDPMLineIndex = "sdpMLineIndex"
    case RTCIceCandidateSDPMid = "sdpMid"
    
    case kNinchatImageCacheKey = "ninchatsdk.swift.VideoThumbnailImageCache"
}

enum NotificationConstants: String {
    case kChannelMessageNotification =  "ninchatsdk.ChannelMessageNotification"
    case kNINWebRTCSignalNotification = "ninchatsdk.NWebRTCSignalNotification"
    case kNINChannelClosedNotification = "ninchatsdk.ChannelClosedNotification"
    case kNINQueuedNotification = "ninchatsdk.QueuedNotification"
}

enum TimeConstants: TimeInterval {
    case kTimerTickInterval = 0.05
    case kMessageMaxAge = 1.0
    case kAnimationDuration = 0.3
    case kAnimationDelay = 1.5
}

enum Margins: CGFloat {
    case kButtonHeight = 45.0
    case kComposeVerticalMargin = 10.0
    case kComposeHorizontalMargin = 60.0
}