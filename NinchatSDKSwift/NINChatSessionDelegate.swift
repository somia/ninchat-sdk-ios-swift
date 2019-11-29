//
//  NINChatSessionDelegate.swift
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 22.11.2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

import NinchatSDK
import NinchatLowLevelClient
import UIKit

/**
* Delegate protocol for NINChatSession class. All the methods are called on
* the main thread.
*/
public protocol NINChatSessionDelegate: class {
    /**
    * Implemeent this if you want to receive debug/error logging from the SDK.
    *
    * Optional method.
    */
    func didOutputSDKLog(session: NINChatSession, value: String)
    
    /**
    * Exposes the low-level events. See the Ninchat API specification for more info.
    *
    * Optional method.
    */
    func onLowLevelEvent(session: NINChatSession, params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool)
    
    /**
    * This method allows the SDK user to override image assets used in the
    * SDK UI. If the implementation does not wish to override a specific asset, nil should
    * be returned for that key.
    *
    * For available asset key constants, see documentation.
    *
    * Optional method.
    */
    func overrideImageAsset(session: NINChatSession, forKey assetKey: AssetConstants) -> UIImage?
    
    /**
    * This method allows the SDK user to override color assets used in the SDK UI.
    * If the implementation does not wish to override a specific asset, nil should
    * be returned for that key.
    *
    * For available asset key constants, see documentation.
    *
    * Optional method.
    */
    func overrideColorAsset(session: NINChatSession, forKey assetKey: ColorConstants) -> UIColor?
    
    /**
    * Indicates that the Ninchat SDK UI has completed its chat. and would like
    * to be closed. The API caller should remove the Ninchat SDK UI from
    * its view hierarchy.
    */
    func didEndSession(session: NINChatSession)
}

extension NINChatSessionDelegate {
    func didOutputSDKLog(session: NINChatSession, log: String) { }
    
    func onLowLevelEvent(session: NINChatSession, params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) { }
    
    func overrideImageAsset(session: NINChatSession, forKey assetKey: AssetConstants) -> UIImage? {
        return nil
    }
    
    func overrideColorAsset(session: NINChatSession, forKey assetKey: ColorConstants) -> UIColor? {
        return nil
    }
}
