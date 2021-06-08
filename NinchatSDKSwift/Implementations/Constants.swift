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

    /* DEPRECATED
     * Use new keys above or CALayerConstant instead
    */
    @available(*, deprecated, renamed: "ninchatIconLoader")
    case iconLoader
    @available(*, deprecated, renamed: "ninchatIconChatWritingIndicator")
    case chatWritingIndicator
    @available(*, deprecated, renamed: "ninchatChatBackground")
    case chatBackground
    @available(*, deprecated, message: "use CALayerConstant.ninchatPrimaryButton")
    case primaryButton
    @available(*, deprecated, message: "use CALayerConstant.ninchatSecondaryButton")
    case secondaryButton
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatCloseButton")
    case chatCloseButton
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatCloseEmptyButton")
    case chatCloseButtonEmpty
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatCloseButton")
    case iconChatCloseButton
    @available(*, unavailable, message: "the item cannot be overridden by images. use ColorConstants.ninchatColorChatBubbleLeftText and ColorConstants.ninchatColorChatBubbleLeftTint instead")
    case chatBubbleLeft
    @available(*, unavailable, message: "the item cannot be overridden by images. use ColorConstants.ninchatColorChatBubbleLeftText and ColorConstants.ninchatColorChatBubbleLeftTint instead")
    case chatBubbleLeftRepeated
    @available(*, unavailable, message: "the item cannot be overridden by images. use ColorConstants.ninchatColorChatBubbleRightText and ColorConstants.ninchatColorChatBubbleRightTint instead")
    case chatBubbleRight
    @available(*, unavailable, message: "the item cannot be overridden by images. use ColorConstants.ninchatColorChatBubbleRightText and ColorConstants.ninchatColorChatBubbleRightTint instead")
    case chatBubbleRightRepeated
    @available(*, deprecated, renamed: "ninchatChatAvatarRight")
    case chatAvatarRight
    @available(*, deprecated, renamed: "ninchatChatAvatarLeft")
    case chatAvatarLeft
    @available(*, deprecated, renamed: "ninchatChatPlayVideo")
    case chatPlayVideo
    @available(*, deprecated, renamed: "ninchatIconTextareaCamera")
    case iconTextareaCamera
    @available(*, deprecated, renamed: "ninchatIconTextareaAttachment")
    case iconTextareaAttachment
    @available(*, deprecated, renamed: "ninchatIconDownload")
    case iconDownload
    @available(*, deprecated, message: "use CALayerConstant.ninchatTextareaSubmitButton")
    case textareaSubmitButton
    @available(*, deprecated, renamed: "ninchatIconVideoToggleFull")
    case iconVideoToggleFull
    @available(*, deprecated, renamed: "ninchatIconVideoToggleNormal")
    case iconVideoToggleNormal
    @available(*, deprecated, renamed: "ninchatIconVideoSoundOn")
    case iconVideoSoundOn
    @available(*, deprecated, renamed: "ninchatIconVideoSoundOff")
    case iconVideoSoundOff
    @available(*, deprecated, renamed: "ninchatIconVideoMicrophoneOn")
    case iconVideoMicrophoneOn
    @available(*, deprecated, renamed: "ninchatIconVideoMicrophoneOff")
    case iconVideoMicrophoneOff
    @available(*, deprecated, renamed: "ninchatIconVideoCameraOn")
    case iconVideoCameraOn
    @available(*, deprecated, renamed: "ninchatIconVideoCameraOff")
    case iconVideoCameraOff
    @available(*, deprecated, renamed: "ninchatIconVideoHangup")
    case iconVideoHangup
    @available(*, deprecated, renamed: "ninchatIconRatingPositive")
    case iconRatingPositive
    @available(*, deprecated, renamed: "ninchatIconRatingNeutral")
    case iconRatingNeutral
    @available(*, deprecated, renamed: "ninchatIconRatingNegative")
    case iconRatingNegative
    @available(*, deprecated, renamed: "ninchatQuestionnaireBackground")
    case questionnaireBackground
}

/// Color override keys
public typealias NINColorAssetDictionary = [ColorConstants:UIColor]
public enum ColorConstants {
    case ninchatColorButtonPrimaryText
    case ninchatColorButtonSecondaryText
    case ninchatColorButtonCloseChatText
    case ninchatColorInfoText
    case ninchatColorChatName
    case ninchatColorChatTimestamp
    case ninchatColorChatBubbleLeftText
    case ninchatColorChatBubbleRightText
    case ninchatColorChatBubbleLeftTint
    case ninchatColorChatBubbleRightTint
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

    /* DEPRECATED
     * Use new keys above or CALayerConstant instead
    */
    @available(*, deprecated, renamed: "ninchatColorButtonPrimaryText")
    case buttonPrimaryText
    @available(*, deprecated, renamed: "ninchatColorButtonSecondaryText")
    case buttonSecondaryText
    @available(*, deprecated, renamed: "ninchatColorInfoText")
    case infoText
    @available(*, deprecated, renamed: "ninchatColorChatName")
    case chatName
    @available(*, deprecated, renamed: "ninchatColorChatTimestamp")
    case chatTimestamp
    @available(*, deprecated, renamed: "ninchatColorChatBubbleLeftText")
    case chatBubbleLeftText
    @available(*, deprecated, renamed: "ninchatColorChatBubbleRightText")
    case chatBubbleRightText
    @available(*, deprecated, renamed: "ninchatColorChatBubbleLeftTint")
    case chatBubbleLeftTint
    @available(*, deprecated, renamed: "ninchatColorChatBubbleRightTint")
    case chatBubbleRightTint
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatCloseButton")
    case chatCloseButtonBackground
    @available(*, deprecated, renamed: "ninchatColorTextareaText")
    case textareaText
    @available(*, deprecated, message: "use CALayerConstant.ninchatTextareaSubmitButton")
    case textareaSubmit
    @available(*, deprecated, renamed: "ninchatColorTextareaSubmitText")
    case textareaSubmitText
    @available(*, deprecated, renamed: "ninchatColorTextareaPlaceholder")
    case textareaPlaceholder
    @available(*, deprecated, renamed: "ninchatColorChatBubbleLeftLink")
    case chatBubbleLeftLink
    @available(*, deprecated, renamed: "ninchatColorChatBubbleRightLink")
    case chatBubbleRightLink
    @available(*, deprecated, renamed: "ninchatColorModalTitleText")
    case modalText
    @available(*, deprecated, message: "use CALayerConstant.ninchatModalTop and CALayerConstant.ninchatModalBottom")
    case modalBackground
    @available(*, deprecated, message: "use CALayerConstant.ninchatBackgroundTop")
    case backgroundTop
    @available(*, deprecated, renamed: "ninchatColorTextTop")
    case textTop
    @available(*, deprecated, renamed: "ninchatColorTextBottom")
    case textBottom
    @available(*, deprecated, renamed: "ninchatColorLink")
    case link
    @available(*, deprecated, message: "use CALayerConstant.ninchatBackgroundBottom")
    case backgroundBottom
    @available(*, deprecated, renamed: "ninchatColorRatingPositiveText")
    case ratingPositiveText
    @available(*, deprecated, renamed: "ninchatColorRatingNeutralText")
    case ratingNeutralText
    @available(*, deprecated, renamed: "ninchatColorRatingNegativeText")
    case ratingNegativeText
}

/// Layer override keys
public let LAYER_NAME = "_ninchat-asset"
public enum CALayerConstant {
    case ninchatPrimaryButton
    case ninchatSecondaryButton
    case ninchatChatCloseButton
    case ninchatChatCloseEmptyButton
    case ninchatTextareaSubmitButton
    case ninchatModalTop
    case ninchatModalBottom
    case ninchatBackgroundTop
    case ninchatBackgroundBottom
    case ninchatQuestionnaireRadioSelected
    case ninchatQuestionnaireRadioUnselected
    case ninchatQuestionnaireNavigationNext
    case ninchatQuestionnaireNavigationBack
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

    /* DEPRECATED
     * Use new keys above or CALayerConstant instead
    */
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorTitleText")
    case titleTextColor
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorTextInput")
    case textInputColor
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorRadioSelectedText")
    case radioPrimaryText
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorRadioUnselectedText")
    case radioSecondaryText
    @available(*, deprecated, message: "use CALayerConstant.ninchatQuestionnaireRadioSelected")
    case radioPrimaryBackground
    @available(*, deprecated, message: "use CALayerConstant.ninchatQuestionnaireRadioUnselected")
    case radioSecondaryBackground
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorCheckboxSelectedText")
    case checkboxPrimaryText
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorCheckboxUnselectedText")
    case checkboxSecondaryText
    @available(*, deprecated, renamed: "ninchatQuestionnaireCheckboxSelectedIndicator")
    case checkboxSelectedIndicator
    @available(*, deprecated, renamed: "ninchatQuestionnaireCheckboxUnselectedIndicator")
    case checkboxDeselectedIndicator
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorSelectSelectedText")
    case selectSelectedText
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorSelectUnselectText")
    case selectNormalText
    @available(*, deprecated, renamed: "ninchatQuestionnaireSelectSelected")
    case selectSelectedBackground
    @available(*, deprecated, renamed: "ninchatQuestionnaireSelectUnselected")
    case selectDeselectedBackground
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorNavigationNextText")
    case navigationNextText
    @available(*, deprecated, renamed: "ninchatQuestionnaireColorNavigationBackText")
    case navigationBackText
    @available(*, deprecated, message: "use CALayerConstant.ninchatQuestionnaireNavigationNext")
    case navigationNextBackground
    @available(*, deprecated, message: "use CALayerConstant.ninchatQuestionnaireNavigationBack")
    case navigationBackBackground
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
    case kBannerAnimationDuration = 5.0
    case kAnimationDelay = 1.5
}

enum Margins: CGFloat {
    case kButtonHeight = 45.0
    case kComposeVerticalMargin = 10.0
    case kComposeHorizontalMargin = 60.0
    case kTextFieldPaddingHeight = 61.0
}
