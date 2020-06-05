//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

/**
* Delegate protocol for NINChatSession class. All the methods are called on
* the main thread.
*/
public protocol NINChatSessionDelegate: class {
    /**
    * Implement this if you want to receive debug/error logging from the SDK.
    *
    * Optional method.
    */
    func ninchat(_ session: NINChatSession, didOutputSDKLog message: String)
    
    /**
    * Exposes the low-level events. See the Ninchat API specification for more info.
    *
    * Optional method.
    */
    func ninchat(_ session: NINChatSession, onLowLevelEvent params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool)
    
    /**
    * This method allows the SDK user to override image assets used in the
    * SDK UI. If the implementation does not wish to override a specific asset, nil should
    * be returned for that key.
    *
    * For available asset key constants, see documentation.
    *
    * Optional method.
    */
    func ninchat(_ session: NINChatSession, overrideImageAssetForKey assetKey: AssetConstants) -> UIImage?
    
    /**
    * This method allows the SDK user to override color assets used in the SDK UI.
    * If the implementation does not wish to override a specific asset, nil should
    * be returned for that key.
    *
    * For available asset key constants, see documentation.
    *
    * Optional method.
    */
    func ninchat(_ session: NINChatSession, overrideColorAssetForKey assetKey: ColorConstants) -> UIColor?

    /**
    * This method allows the SDK user to override color assets for questionnaires used in the SDK UI.
    * If the implementation does not wish to override a specific asset, nil should
    * be returned for that key.
    *
    * For available asset key constants, see documentation.
    *
    * Optional method.
    */
    func ninchat(_ session: NINChatSession, overrideQuestionnaireColorAssetKey assetKey: QuestionnaireColorConstants) -> UIColor?

    /**
    * Indicates that the Ninchat SDK UI has completed its chat. and would like
    * to be closed. The API caller should remove the Ninchat SDK UI from
    * its view hierarchy.
    */
    func ninchatDidEnd(_ ninchat: NINChatSession)

    /**
    * The function is called when SDK cannot continue a session using provided credentials with `start(credentials:completion:)`.
    * The function could be used to clear saved credentials
    *
    * The return value indicates if the SDK should initiate a new chat session or not.
    */
    func ninchatDidFail(toResumeSession session: NINChatSession) -> Bool
}

extension NINChatSessionDelegate {
    func ninchat(_ session: NINChatSession, didOutputSDKLog message: String) { }

    func ninchat(_ session: NINChatSession, onLowLevelEvent params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) { }

    func ninchat(_ session: NINChatSession, overrideImageAssetForKey assetKey: AssetConstants) -> UIImage? { nil }

    func ninchat(_ session: NINChatSession, overrideColorAssetForKey assetKey: ColorConstants) -> UIColor? { nil }

    func ninchat(_ session: NINChatSession, overrideQuestionnaireColorAssetKey assetKey: QuestionnaireColorConstants) -> UIColor? { nil }

    func ninchatDidFail(toResumeSession session: NINChatSession) -> Bool { false }
}
