//
// Copyright (c) 6.5.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

/**
* Delegate protocol for NINChatSession SwiftUI Views.
*/
public protocol NinchatSwiftUIDelegate: AnyObject {
    @available(iOS 13.0, *)
    func ninchat(_ session: NINChatSession, overrideViewForKey key: SwiftUIConstants) -> NinchatSwiftUIOverrideOptions?
}

extension NinchatSwiftUIDelegate {
    @available(iOS 13.0, *)
    func ninchat(_ session: NINChatSession, overrideViewForKey key: SwiftUIConstants) -> NinchatSwiftUIOverrideOptions? { nil }
}
