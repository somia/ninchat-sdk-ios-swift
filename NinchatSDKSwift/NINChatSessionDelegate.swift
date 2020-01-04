//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

/**
* Delegate protocol for NINChatSession class. All the methods are called on
* the main thread.
*/
public protocol NINChatSessionDelegateSwift: class {
    /**
    * Implemeent this if you want to receive debug/error logging from the SDK.
    *
    * Optional method.
    */
    func didOutputSDKLog(session: NINChatSessionSwift, value: String)
    
    /**
    * Exposes the low-level events. See the Ninchat API specification for more info.
    *
    * Optional method.
    */
    func onLowLevelEvent(session: NINChatSessionSwift, params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool)
    
    /**
    * This method allows the SDK user to override image assets used in the
    * SDK UI. If the implementation does not wish to override a specific asset, nil should
    * be returned for that key.
    *
    * For available asset key constants, see documentation.
    *
    * Optional method.
    */
    func overrideImageAsset(session: NINChatSessionSwift, forKey assetKey: AssetConstants) -> UIImage?
    
    /**
    * This method allows the SDK user to override color assets used in the SDK UI.
    * If the implementation does not wish to override a specific asset, nil should
    * be returned for that key.
    *
    * For available asset key constants, see documentation.
    *
    * Optional method.
    */
    func overrideColorAsset(session: NINChatSessionSwift, forKey assetKey: ColorConstants) -> UIColor?
    
    /**
    * Indicates that the Ninchat SDK UI has completed its chat. and would like
    * to be closed. The API caller should remove the Ninchat SDK UI from
    * its view hierarchy.
    */
    func didEndSession(session: NINChatSessionSwift)
}

extension NINChatSessionDelegateSwift {
    func didOutputSDKLog(session: NINChatSessionSwift, log: String) { }
    
    func onLowLevelEvent(session: NINChatSessionSwift, params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) { }
    
    func overrideImageAsset(session: NINChatSessionSwift, forKey assetKey: AssetConstants) -> UIImage? {
        return nil
    }
    
    func overrideColorAsset(session: NINChatSessionSwift, forKey assetKey: ColorConstants) -> UIColor? {
        return nil
    }
}
