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
    func override(imageAsset key: AssetConstants) -> UIImage?
    func override(colorAsset key: ColorConstants) -> UIColor?
}

extension NINChatSessionSwift: NINChatSessionInternalDelegate {
    internal func log(value: String) {
        DispatchQueue.main.async {
            self.delegate?.didOutputSDKLog(session: self, value: value)
            self.didOutputSDKLog?(self, value)
        }
    }
    
    internal func log(format: String, _ args: CVarArg...) {
        DispatchQueue.main.async {
            self.delegate?.didOutputSDKLog(session: self, value: String(format: format, args))
            self.didOutputSDKLog?(self, String(format: format, args))
        }
    }
    
    internal func onLowLevelEvent(event: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
        DispatchQueue.main.async {
            self.delegate?.onLowLevelEvent(session: self, params: event, payload: payload, lastReply: lastReply)
            self.onLowLevelEvent?(self, event, payload, lastReply)
        }
    }
    
    internal func onDidEnd() {
        DispatchQueue.main.async {
            self.delegate?.didEndSession(session: self)
            self.didEndSession?(self)
        }
    }
    
    internal func override(imageAsset key: AssetConstants) -> UIImage? {
        if let delegate = self.delegate {
            return delegate.overrideImageAsset(session: self, forKey: key)
        }
        return self.overrideImageAsset?(self, key)
    }
    
    internal func override(colorAsset key: ColorConstants) -> UIColor? {
        if let delegate = self.delegate {
            return delegate.overrideColorAsset(session: self, forKey: key)
        }
        return self.overrideColorAsset?(self, key)
    }
}
