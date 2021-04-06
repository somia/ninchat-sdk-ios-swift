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
    case ninchatIconTextareaCamera
    case ninchatIconTextareaAttachment
    case ninchatIconDownload
    case ninchatIconVideoToggleFull
    case ninchatIconVideoToggleNormal
    case ninchatIconVideoSoundOn
    case ninchatIconVideoSoundOff
    case ninchatIconVideoMicrophoneOn
    case ninchatIconVideoMicrophoneOff
    case ninchatIconVideoCameraOn
    case ninchatIconVideoCameraOff
    case ninchatIconVideoHangup
    case ninchatIconRatingPositive
    case ninchatIconRatingNeutral
    case ninchatIconRatingNegative

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
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatCloseButton")
    case chatCloseButtonEmpty
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatCloseButton")
    case iconChatCloseButton
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatBubbleLeft")
    case chatBubbleLeft
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatBubbleLeftRepeated")
    case chatBubbleLeftRepeated
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatBubbleRight")
    case chatBubbleRight
    @available(*, deprecated, message: "use CALayerConstant.ninchatChatBubbleRightRepeated")
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


    @available(*, deprecated, message: "use QuestionnaireAssetConstants.questionnaireBackground")
    case questionnaireBackground
    /*
     * ninchat_icon_textarea_submit_button
     * ninchat_ui_compose_select_button
     * ninchat_ui_compose_select_button_selected
     * ninchat_ui_compose_select_submit
     */
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
    @available(*, deprecated, message: "use CALayerConstant.ninchatModal")
    case modalBackground
    @available(*, deprecated, message: "use CALayerConstant.ninchatBackground")
    case backgroundTop
    @available(*, deprecated, renamed: "ninchatColorTextTop")
    case textTop
    @available(*, deprecated, renamed: "ninchatColorTextBottom")
    case textBottom
    @available(*, deprecated, renamed: "ninchatColorLink")
    case link
    @available(*, deprecated, message: "use CALayerConstant.ninchatBackground")
    case backgroundBottom
    @available(*, deprecated, renamed: "ninchatColorRatingPositiveText")
    case ratingPositiveText
    @available(*, deprecated, renamed: "ninchatColorRatingNeutralText")
    case ratingNeutralText
    @available(*, deprecated, renamed: "ninchatColorRatingNegativeText")
    case ratingNegativeText
}

/// Color override keys
public typealias NINLayerAssetDictionary = [CALayerConstant:CALayer]
public let LAYER_NAME = "_ninchat-asset"
public enum CALayerConstant {
    case ninchatPrimaryButton
    case ninchatSecondaryButton
    case ninchatChatBubbleLeft
    case ninchatChatBubbleRight
    case ninchatChatBubbleLeftRepeated
    case ninchatChatBubbleRightRepeated
    case ninchatChatCloseButton
    case ninchatTextareaSubmitButton
    case ninchatModal
    case ninchatBackground
}

/// Questionnaire override keys
public typealias NINQuestionnaireDictionary = [QuestionnaireColorConstants:String]
public enum QuestionnaireColorConstants {
    /// Title
    case titleTextColor

    /// Input
    case textInputColor     /// Text color for all inputs

    /// Radio
    case radioPrimaryText   /// Text color for selected elements
    case radioSecondaryText /// Text color for deselected elements
    case radioPrimaryBackground     /// Background color for selected elements
    case radioSecondaryBackground   /// Background color for deselected elements

    /// Checkbox
    case checkboxPrimaryText    /// Text color for selected elements
    case checkboxSecondaryText  /// Text color for deselected elements
    case checkboxSelectedIndicator      /// Tint and border color for selected element's indicator
    case checkboxDeselectedIndicator    /// Tint and border color for deselected element's indicator

    /// Select
    case selectSelectedText /// Text, indicator, and border color for selected state
    case selectNormalText   /// Text, indicator, and border color for normal state
    case selectSelectedBackground   /// Background color for selected state
    case selectDeselectedBackground /// Background color for deselected state

    /// Navigation
    case navigationNextText     /// Text and border color for the next button
    case navigationBackText     /// Text and border color for the back button
    case navigationNextBackground   /// Background color for the next button
    case navigationBackBackground   /// Background color for the back button
}

public enum QuestionnaireAssetConstants {
    /// Background image
    case questionnaireBackground
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
    case kTextFieldPaddingHeight = 61.0
}
