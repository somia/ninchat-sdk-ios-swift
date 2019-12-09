//
//  NINChatSessionClosure.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 9.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import NinchatSDK

public protocol NINChatSessionClosure {
    var didOutputSDKLog: ((NINChatSession, String) -> Void)? { get set }
    var onLowLevelEvent: ((NINChatSession, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)? { get set }
    var overrideImageAsset: ((NINChatSession, AssetConstants) -> UIImage?)? { get set }
    var overrideColorAsset: ((NINChatSession, ColorConstants) -> UIColor?)? { get set }
    var didEndSession: ((NINChatSession) -> Void)? { get set }
}
