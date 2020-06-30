//
// Copyright (c) 5.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

// MARK: - Internal helper methods

protocol NINChatSessionInternalDelegate {
    func log(value: String)
    func log(format: String, _ args: CVarArg...)
    func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool)
    func onDidEnd()
    func onResumeFailed() -> Bool
    func override(imageAsset key: AssetConstants) -> UIImage?
    func override(colorAsset key: ColorConstants) -> UIColor?
    func override(questionnaireAsset key: QuestionnaireColorConstants) -> UIColor?
}

struct InternalDelegate: NINChatSessionInternalDelegate {
    weak var session: NINChatSession?
    init(session: NINChatSession) {
        self.session = session
    }

    internal func log(value: String) {
        DispatchQueue.main.async {
            guard let session = self.session else { return }
            session.delegate?.ninchat(session, didOutputSDKLog: value)
        }
    }
    
    internal func log(format: String, _ args: CVarArg...) {
        DispatchQueue.main.async {
            guard let session = self.session else { return }
            session.delegate?.ninchat(session, didOutputSDKLog: String(format: format, args))
        }
    }
    
    internal func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
        DispatchQueue.main.async {
            guard let session = self.session else { return }
            session.delegate?.ninchat(session, onLowLevelEvent: event, payload: payload, lastReply: lastReply)
        }
    }
    
    internal func onDidEnd() {
        DispatchQueue.main.async {
            guard let session = self.session else { return }
            session.delegate?.ninchatDidEnd(session)
        }
    }

    internal func onResumeFailed() -> Bool {
        guard let session = self.session else { return false }
        return session.delegate?.ninchatDidFail(toResumeSession: session) ?? false
    }

    internal func override(imageAsset key: AssetConstants) -> UIImage? {
        guard let session = self.session else { return nil }
        return session.delegate?.ninchat(session, overrideImageAssetForKey: key)
    }
    
    internal func override(colorAsset key: ColorConstants) -> UIColor? {
        guard let session = self.session else { return nil }
        return session.delegate?.ninchat(session, overrideColorAssetForKey: key)
    }

    internal func override(questionnaireAsset key: QuestionnaireColorConstants) -> UIColor? {
        guard let session = self.session else { return nil }
        return session.delegate?.ninchat(session, overrideQuestionnaireColorAssetKey: key)
    }
}

/// Dictionaries for typing/loading cells
extension NINChatSessionInternalDelegate {
    var imageAssetsDictionary: NINImageAssetDictionary {
        let userTypingIndicator = self.override(imageAsset: .chatWritingIndicator) ?? UIImage.animatedImage(with: [Int](0...23).compactMap({ UIImage(named: "icon_writing_\($0)", in: .SDKBundle, compatibleWith: nil) }), duration: 1.0)
        let leftSideBubble = self.override(imageAsset: .chatBubbleLeft) ?? UIImage(named: "chat_bubble_left", in: .SDKBundle, compatibleWith: nil)
        let leftSideBubbleSeries = self.override(imageAsset: .chatBubbleLeftRepeated) ?? UIImage(named: "chat_bubble_left_series", in: .SDKBundle, compatibleWith: nil)
        let rightSideBubble = self.override(imageAsset: .chatBubbleRight) ?? UIImage(named: "chat_bubble_right", in: .SDKBundle, compatibleWith: nil)
        let rightSideBubbleSeries = self.override(imageAsset: .chatBubbleRightRepeated) ?? UIImage(named: "chat_bubble_right_series", in: .SDKBundle, compatibleWith: nil)
        let leftSideAvatar = self.override(imageAsset: .chatAvatarLeft) ?? UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)
        let rightSideAvatar = self.override(imageAsset: .chatAvatarRight) ?? UIImage(named: "icon_avatar_mine", in: .SDKBundle, compatibleWith: nil)
        let playVideoIcon = self.override(imageAsset: .chatPlayVideo) ?? UIImage(named: "icon_play", in: .SDKBundle, compatibleWith: nil)

        return [.chatWritingIndicator: userTypingIndicator!, .chatBubbleLeft: leftSideBubble!, .chatBubbleLeftRepeated: leftSideBubbleSeries!,
                .chatBubbleRight: rightSideBubble!, .chatBubbleRightRepeated: rightSideBubbleSeries!, .chatAvatarLeft: leftSideAvatar!,
                .chatAvatarRight: rightSideAvatar!, .chatPlayVideo: playVideoIcon!]
    }

    var colorAssetsDictionary: [ColorConstants:UIColor] {
        let colorKeys: [ColorConstants] = [.infoText, .chatName, .chatTimestamp, .chatBubbleLeftText, .chatBubbleRightText, .chatBubbleLeftLink, .chatBubbleRightLink]
        return colorKeys.compactMap({ ($0, self.override(colorAsset: $0)) }).reduce(into: [:]) { (colorAsset: inout [ColorConstants:UIColor], tuple: (key: ColorConstants, color: UIColor?)) in
            colorAsset[tuple.key] = tuple.color
        }
    }
}
