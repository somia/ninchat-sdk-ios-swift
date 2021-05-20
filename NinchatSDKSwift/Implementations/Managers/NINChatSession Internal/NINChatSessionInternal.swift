//
// Copyright (c) 5.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

// MARK: - Internal helper methods

protocol NINChatSessionInternalDelegate: AnyObject {
    func log(value: String)
    func log(format: String, _ args: CVarArg...)
    func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool)
    func onDidEnd()
    func onResumeFailed() -> Bool
    func override(imageAsset key: AssetConstants) -> UIImage?
    func override(colorAsset key: ColorConstants) -> UIColor?
    func override(layerAsset key: CALayerConstant) -> CALayer?
    func override(questionnaireAsset key: QuestionnaireColorConstants) -> UIColor?
}

extension NINChatSession: NINChatSessionInternalDelegate {
    func log(value: String) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.ninchat(self, didOutputSDKLog: value)
        }
    }

    func log(format: String, _ args: CVarArg...) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.ninchat(self, didOutputSDKLog: String(format: format, args))
        }
    }

    func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.ninchat(self, onLowLevelEvent: event, payload: payload, lastReply: lastReply)
        }
    }
    
    func onDidEnd() {
        /// According to https://github.com/somia/mobile/issues/287
        /// Clear metadata from the UserDefaults on a normal close
        UserDefaults.remove(forKey: .metadata)

        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.ninchatDidEnd(self)
        }
    }

    func onResumeFailed() -> Bool {
        weak var `self` = self
        guard let `self` = self else { return false }
        return self.delegate?.ninchatDidFail(toResumeSession: self) ?? false
    }

    func override(imageAsset key: AssetConstants) -> UIImage? {
        /// TODO: REMOVE legacy keys
        let deprecatedKeys: [AssetConstants:AssetConstants] = [
            .ninchatIconLoader: .iconLoader,
            .ninchatIconChatWritingIndicator: .chatWritingIndicator,
            .ninchatChatBackground: .chatBackground,
            .ninchatChatAvatarRight: .chatAvatarRight,
            .ninchatChatAvatarLeft: .chatAvatarLeft,
            .ninchatChatPlayVideo: .chatPlayVideo,
            .ninchatIconTextareaCamera: .iconTextareaCamera,
            .ninchatIconTextareaAttachment: .iconTextareaAttachment,
            .ninchatIconDownload: .iconDownload,
            .ninchatIconVideoToggleFull: .iconVideoToggleFull,
            .ninchatIconVideoToggleNormal: .iconVideoToggleNormal,
            .ninchatIconVideoSoundOn: .iconVideoSoundOn,
            .ninchatIconVideoSoundOff: .iconVideoSoundOff,
            .ninchatIconVideoMicrophoneOn: .iconVideoMicrophoneOn,
            .ninchatIconVideoMicrophoneOff: .iconVideoMicrophoneOff,
            .ninchatIconVideoCameraOn: .iconVideoCameraOn,
            .ninchatIconVideoCameraOff: .iconVideoCameraOff,
            .ninchatIconVideoHangup: .iconVideoHangup,
            .ninchatIconRatingPositive: .iconRatingPositive,
            .ninchatIconRatingNeutral: .iconRatingNeutral,
            .ninchatIconRatingNegative: .iconRatingNegative,
            .ninchatQuestionnaireBackground: .questionnaireBackground
        ]

        weak var `self` = self
        guard let `self` = self else { return nil }
        
        if let asset = self.delegate?.ninchat(self, overrideImageAssetForKey: key) {
            return asset
        }
        guard let depKey = deprecatedKeys[key] else { return nil }
        return self.delegate?.ninchat(self, overrideImageAssetForKey: depKey)
    }

    func override(colorAsset key: ColorConstants) -> UIColor? {
        /// TODO: REMOVE legacy keys
        let deprecatedKeys: [ColorConstants:ColorConstants] = [
            .ninchatColorButtonPrimaryText: .buttonPrimaryText,
            .ninchatColorButtonSecondaryText: .buttonSecondaryText,
            .ninchatColorInfoText: .infoText,
            .ninchatColorChatName: .chatName,
            .ninchatColorChatTimestamp: .chatTimestamp,
            .ninchatColorChatBubbleLeftText: .chatBubbleLeftText,
            .ninchatColorChatBubbleRightText: .chatBubbleRightText,
            .ninchatColorChatBubbleLeftTint: .chatBubbleLeftTint,
            .ninchatColorChatBubbleRightTint: .chatBubbleRightTint,
            .ninchatColorTextareaText: .textareaText,
            .ninchatColorTextareaSubmitText: .textareaSubmitText,
            .ninchatColorTextareaPlaceholder: .textareaPlaceholder,
            .ninchatColorChatBubbleLeftLink: .chatBubbleLeftLink,
            .ninchatColorChatBubbleRightLink: .chatBubbleRightLink,
            .ninchatColorModalTitleText: .modalText,
            .ninchatColorTextTop: .textTop,
            .ninchatColorTextBottom: .textBottom,
            .ninchatColorLink: .link,
            .ninchatColorRatingPositiveText: .ratingPositiveText,
            .ninchatColorRatingNeutralText: .ratingNeutralText,
            .ninchatColorRatingNegativeText: .ratingNegativeText
        ]

        weak var `self` = self
        guard let `self` = self else { return nil }
        
        if let color = self.delegate?.ninchat(self, overrideColorAssetForKey: key) {
            return color
        }
        guard let depKey = deprecatedKeys[key] else { return nil }
        return self.delegate?.ninchat(self, overrideColorAssetForKey: depKey)
    }

    func override(layerAsset key: CALayerConstant) -> CALayer? {
        weak var `self` = self
        guard let `self` = self else { return nil }
        
        let layer = self.delegate?.ninchat(self, overrideLayer: key)
        layer?.name = LAYER_NAME
        return layer
    }

    func override(questionnaireAsset key: QuestionnaireColorConstants) -> UIColor? {
        /// TODO: REMOVE legacy keys
        let deprecatedKeys: [QuestionnaireColorConstants:QuestionnaireColorConstants] = [
            .ninchatQuestionnaireColorTitleText: .titleTextColor,
            .ninchatQuestionnaireColorTextInput: .textInputColor,
            .ninchatQuestionnaireColorRadioSelectedText: .radioPrimaryText,
            .ninchatQuestionnaireColorRadioUnselectedText: .radioSecondaryText,
            .ninchatQuestionnaireColorCheckboxSelectedText: .checkboxPrimaryText,
            .ninchatQuestionnaireColorCheckboxUnselectedText: .checkboxSecondaryText,
            .ninchatQuestionnaireColorSelectSelectedText: .selectSelectedText,
            .ninchatQuestionnaireColorSelectUnselectText: .selectNormalText,
            .ninchatQuestionnaireColorNavigationNextText: .navigationNextText,
            .ninchatQuestionnaireColorNavigationBackText: .navigationBackText,
            .ninchatQuestionnaireCheckboxSelectedIndicator: .checkboxSelectedIndicator,
            .ninchatQuestionnaireCheckboxUnselectedIndicator: .checkboxDeselectedIndicator,
            .ninchatQuestionnaireSelectSelected: .selectSelectedBackground,
            .ninchatQuestionnaireSelectUnselected: .selectDeselectedBackground
        ]
        
        weak var `self` = self
        guard let `self` = self else { return nil }
        
        if let color = self.delegate?.ninchat(self, overrideQuestionnaireColorAssetKey: key) {
            return color
        }
        guard let depKey = deprecatedKeys[key] else { return nil }
        return self.delegate?.ninchat(self, overrideQuestionnaireColorAssetKey: depKey)
    }
}

/// Dictionaries for typing/loading cells
extension NINChatSessionInternalDelegate {
    var imageAssetsDictionary: NINImageAssetDictionary {
        let userTypingIndicator = self.override(imageAsset: .ninchatIconChatWritingIndicator) ?? UIImage.animatedImage(with: [Int](0...23).compactMap({ UIImage(named: "icon_writing_\($0)", in: .SDKBundle, compatibleWith: nil) }), duration: 1.0)
        let leftSideAvatar = self.override(imageAsset: .ninchatChatAvatarLeft) ?? UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)
        let rightSideAvatar = self.override(imageAsset: .ninchatChatAvatarRight) ?? UIImage(named: "icon_avatar_mine", in: .SDKBundle, compatibleWith: nil)
        let playVideoIcon = self.override(imageAsset: .ninchatChatPlayVideo) ?? UIImage(named: "icon_play", in: .SDKBundle, compatibleWith: nil)

        return [.ninchatIconChatWritingIndicator: userTypingIndicator!, .ninchatChatAvatarLeft: leftSideAvatar!,
                .ninchatChatAvatarRight: rightSideAvatar!, .ninchatChatPlayVideo: playVideoIcon!]
    }

    var colorAssetsDictionary: [ColorConstants:UIColor] {
        let colorKeys: [ColorConstants] = [.ninchatColorInfoText, .ninchatColorChatName, .ninchatColorChatTimestamp, .ninchatColorChatBubbleLeftText, .ninchatColorChatBubbleLeftTint, .ninchatColorChatBubbleRightText, .ninchatColorChatBubbleRightTint, .ninchatColorChatBubbleLeftLink, .ninchatColorChatBubbleRightLink]
        return colorKeys.compactMap({ ($0, self.override(colorAsset: $0)) }).reduce(into: [:]) { (colorAsset: inout [ColorConstants:UIColor], tuple: (key: ColorConstants, color: UIColor?)) in
            colorAsset[tuple.key] = tuple.color
        }
    }
}
