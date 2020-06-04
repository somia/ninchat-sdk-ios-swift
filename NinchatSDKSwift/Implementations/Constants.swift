//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import UIKit

// MARK: - Override Keys

/// Assets override keys
public typealias NINImageAssetDictionary = [AssetConstants:UIImage]
public enum AssetConstants {
    case iconLoader
    case iconChatCloseButton
    case iconRatingPositive
    case iconRatingNeutral
    case iconRatingNegative
    case iconTextareaCamera
    case iconTextareaAttachment
    case iconDownload
    case iconTextareaSubmitButtonIcon
    case iconVideoToggleFull
    case iconVideoToggleNormal
    case iconVideoSoundOn
    case iconVideoSoundOff
    case iconVideoMicrophoneOn
    case iconVideoMicrophoneOff
    case iconVideoCameraOn
    case iconVideoCameraOff
    case iconVideoHangup
    case chatWritingIndicator
    case chatBackground
    case chatCloseButton
    case chatBubbleLeft
    case chatBubbleLeftRepeated
    case chatBubbleRight
    case chatBubbleRightRepeated
    case chatAvatarRight
    case chatAvatarLeft
    case chatPlayVideo
    case textareaSubmitButton
    case primaryButton
    case secondaryButton
}

/// Color override keys
public typealias NINColorAssetDictionary = [ColorConstants:UIColor]
public enum ColorConstants {
    case buttonPrimaryText
    case buttonSecondaryText
    case infoText
    case chatName
    case chatTimestamp
    case chatBubbleLeftText
    case chatBubbleRightText
    case textareaText
    case textareaSubmitText
    case chatBubbleLeftLink
    case chatBubbleRightLink
    case modalText
    case modalBackground
    case backgroundTop
    case textTop
    case textBottom
    case link
    case backgroundBottom
    case ratingPositiveText
    case ratingNeutralText
    case ratingNegativeText
}


// MARK: - Constants used within the SDK

public enum Constants: String {
    case kTestServerAddress = "api.luupi.net"
    case kProductionServerAddress = "api.ninchat.com"
    
    case kCloseWindowText = "Close window"
    case kJoinQueueText = "Join audience queue {{audienceQueue.queue_attrs.name}}"
    case kQueuePositionN = "Joined audience queue {{audienceQueue.queue_attrs.name}}, you are at position {{audienceQueue.queue_position}}."
    case kQueuePositionNext = "Joined audience queue {{audienceQueue.queue_attrs.name}}, you are next."
    case kCloseChatText = "Close chat"
    case kConversationEnded = "Conversation ended"
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
    case kTextFieldPaddingHeight = 64.0
}
