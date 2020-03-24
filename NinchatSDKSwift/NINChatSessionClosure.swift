//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

public protocol NINChatSessionClosure {
    var didOutputSDKLog: ((NINChatSessionSwift, String) -> Void)? { get set }
    var onLowLevelEvent: ((NINChatSessionSwift, NINLowLevelClientProps, NINLowLevelClientPayload, Bool) -> Void)? { get set }
    var overrideImageAsset: ((NINChatSessionSwift, AssetConstants) -> UIImage?)? { get set }
    var overrideColorAsset: ((NINChatSessionSwift, ColorConstants) -> UIColor?)? { get set }
    var didEndSession: ((NINChatSessionSwift) -> Void)? { get set }
}
