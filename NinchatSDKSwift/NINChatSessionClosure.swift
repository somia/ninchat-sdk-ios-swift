//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import NinchatSDK

public protocol NINChatSessionClosure {
    var didOutputSDKLog: ((NINChatSession, String) -> Void)? { get set }
    var onLowLevelEvent: ((NINChatSession, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)? { get set }
    var overrideImageAsset: ((NINChatSession, AssetConstants) -> UIImage?)? { get set }
    var overrideColorAsset: ((NINChatSession, ColorConstants) -> UIColor?)? { get set }
    var didEndSession: ((NINChatSession) -> Void)? { get set }
}
