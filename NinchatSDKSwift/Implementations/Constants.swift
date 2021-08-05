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
    case ninchatIconLoader
    case ninchatIconChatWritingIndicator
    case ninchatChatBackground
    case ninchatChatAvatarRight
    case ninchatChatAvatarLeft
    case ninchatChatPlayVideo
    case ninchatIconTextareaCamera      /* not used */
    case ninchatIconTextareaAttachment
    case ninchatIconMetadata
    case ninchatIconDownload
    case ninchatIconVideoToggleFull     /* not used */
    case ninchatIconVideoToggleNormal   /* not used */
    case ninchatIconVideoSoundOn        /* not used */
    case ninchatIconVideoSoundOff       /* not used */
    case ninchatIconVideoMicrophoneOn
    case ninchatIconVideoMicrophoneOff
    case ninchatIconVideoCameraOn
    case ninchatIconVideoCameraOff
    case ninchatIconVideoHangup
    case ninchatIconRatingPositive
    case ninchatIconRatingNeutral
    case ninchatIconRatingNegative
    case ninchatQuestionnaireBackground
}

/// Color override keys
public typealias NINColorAssetDictionary = [ColorConstants:UIColor]
public enum ColorConstants {
    case ninchatColorButtonPrimaryText
    case ninchatColorButtonSecondaryText
    case ninchatColorInfoText
    case ninchatColorChatName
    case ninchatColorChatTimestamp
    case ninchatColorChatBubbleLeftText
    case ninchatColorChatBubbleRightText
    case ninchatColorChatBubbleLeftTint
    case ninchatColorChatBubbleRightTint
    case ninchatColorChatBubbleComposeTint
    case ninchatColorTextareaText
    case ninchatColorTextareaPlaceholder
    case ninchatColorTextareaSubmitText
    case ninchatColorChatBubbleLeftLink
    case ninchatColorChatBubbleRightLink
    case ninchatColorModalTitleText
    case ninchatColorTextTop
    case ninchatColorTextBottom
    case ninchatColorLink
    case ninchatColorRatingPositiveText
    case ninchatColorRatingNeutralText
    case ninchatColorRatingNegativeText
    case ninchatColorTitlebarPlaceholder
    
    /// "Close chat" button in top right corner
    case ninchatColorCloseChatText
    /// "Close" button in titlebar
    case ninchatColorTitlebarCloseText
    /// "Close chat" button after conversation is ended
    case ninchatColorCloseText
}

/// Layer override keys
public let LAYER_NAME = "_ninchat-asset"
public enum CALayerConstant {
    case ninchatPrimaryButton
    case ninchatSecondaryButton
    case ninchatComposeSelectedButton
    case ninchatComposeUnselectedButton
    case ninchatComposeSubmitButton
    case ninchatComposeSubmitSelectedButton
    case ninchatTextareaSubmitButton
    case ninchatColorTextareaTextInput
    case ninchatMetadataContainer
    case ninchatModalTop
    case ninchatModalBottom
    case ninchatBackgroundTop
    case ninchatBackgroundBottom
    case ninchatQuestionnaireRadioSelected
    case ninchatQuestionnaireRadioUnselected
    case ninchatQuestionnaireNavigationNext
    case ninchatQuestionnaireNavigationBack
    /// "Close chat" button in top right corner
    case ninchatChatCloseButton
    case ninchatChatCloseEmptyButton
    /// "Close" button in titlebar
    case ninchatTitlebarCloseButton
    case ninchatTitlebarCloseEmptyButton
    /// "Close chat" button after conversation is ended
    case ninchatCloseButton
    case ninchatCloseEmptyButton
}

/// Questionnaire color override keys
public enum QuestionnaireColorConstants {
    case ninchatQuestionnaireColorTitleText
    case ninchatQuestionnaireColorTextInput
    case ninchatQuestionnaireColorRadioSelectedText
    case ninchatQuestionnaireColorRadioUnselectedText
    case ninchatQuestionnaireColorCheckboxSelectedText
    case ninchatQuestionnaireCheckboxSelectedIndicator
    case ninchatQuestionnaireColorCheckboxUnselectedText
    case ninchatQuestionnaireCheckboxUnselectedIndicator
    case ninchatQuestionnaireColorSelectSelectedText
    case ninchatQuestionnaireSelectSelected
    case ninchatQuestionnaireColorSelectUnselectText
    case ninchatQuestionnaireSelectUnselected
    case ninchatQuestionnaireColorNavigationNextText
    case ninchatQuestionnaireColorNavigationBackText
}

// MARK: - Constants used within the SDK

public enum Constants: String {
    case kTestServerAddress = "api.luupi.net"
    case kProductionServerAddress = "api.ninchat.com"
    
    case kCloseWindowText = "Close window"
    case kCloseText = "Close"
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
    case kBannerAnimationDuration = 5.0
    case kAnimationDelay = 1.5
}

enum Margins: CGFloat {
    case kButtonHeight = 45.0
    case kComposeVerticalMargin = 10.0
    case kComposeHorizontalMargin = 60.0
    case kTextFieldPaddingHeight = 61.0
}
