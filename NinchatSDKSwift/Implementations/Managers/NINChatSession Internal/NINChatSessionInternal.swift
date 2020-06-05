//
// Copyright (c) 5.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

// MARK: - Internal helper methods

protocol NINChatSessionInternalDelegate: class {
    func log(value: String)
    func log(format: String, _ args: CVarArg...)
    func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool)
    func onDidEnd()
    func onResumeFailed() -> Bool
    func override(imageAsset key: AssetConstants) -> UIImage?
    func override(colorAsset key: ColorConstants) -> UIColor?
    func override(questionnaireAsset key: QuestionnaireColorConstants) -> UIColor?
}

extension NINChatSession: NINChatSessionInternalDelegate {
    internal func log(value: String) {
        DispatchQueue.main.async {
            self.delegate?.ninchat(self, didOutputSDKLog: value)
        }
    }
    
    internal func log(format: String, _ args: CVarArg...) {
        DispatchQueue.main.async {
            self.delegate?.ninchat(self, didOutputSDKLog: String(format: format, args))
        }
    }
    
    internal func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
        DispatchQueue.main.async {
            self.delegate?.ninchat(self, onLowLevelEvent: event, payload: payload, lastReply: lastReply)
        }
    }
    
    internal func onDidEnd() {
        DispatchQueue.main.async {
            self.delegate?.ninchatDidEnd(self)
        }
    }

    internal func onResumeFailed() -> Bool {
        self.delegate?.ninchatDidFail(toResumeSession: self) ?? false
    }

    internal func override(imageAsset key: AssetConstants) -> UIImage? {
        delegate?.ninchat(self, overrideImageAssetForKey: key)
    }
    
    internal func override(colorAsset key: ColorConstants) -> UIColor? {
        delegate?.ninchat(self, overrideColorAssetForKey: key)
    }

    internal func override(questionnaireAsset key: QuestionnaireColorConstants) -> UIColor? {
        delegate?.ninchat(self, overrideQuestionnaireColorAssetKey: key)
    }
}
