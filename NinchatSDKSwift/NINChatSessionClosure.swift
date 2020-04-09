//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

/// Having Closures and Delegates together might result in confusion for the customers
/// Additionally, the consistency might be violated when both patterns are usable.
/// Thus, the following would be dismissed.

/*
public protocol NINChatSessionClosure {
    var didOutputSDKLog: ((NINChatSession, String) -> Void)? { get set }
    var onLowLevelEvent: ((NINChatSession, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)? { get set }
    var overrideImageAsset: ((NINChatSession, AssetConstants) -> UIImage?)? { get set }
    var overrideColorAsset: ((NINChatSession, ColorConstants) -> UIColor?)? { get set }
    var didEndSession: ((NINChatSession) -> Void)? { get set }
    var didFailToResume: ((NINChatSession?) -> Bool)? { get set }
}
*/