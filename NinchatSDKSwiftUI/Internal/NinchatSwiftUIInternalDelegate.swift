//
// Copyright (c) 6.5.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

typealias InternalSwiftUIDelegate = NinchatSwiftUIInternalDelegate

struct NinchatSwiftUIInternalDelegate {
    weak var session: NINChatSession?
    init(session: NINChatSession) {
        self.session = session
    }
    
    func overrideView(_ key: SwiftUIConstants) -> NinchatSwiftUIOverrideOptions? {
        guard let session = self.session else { return nil }
        return session.delegateSwiftUI?.ninchat(session, overrideViewForKey: key)
    }
}
