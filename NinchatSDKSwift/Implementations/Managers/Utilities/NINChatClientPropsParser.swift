//
// Copyright (c) 21.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

final class NINChatClientPropsParser: NSObject, NINLowLevelClientPropVisitorProtocol {
    
    private(set) var properties: [String:Any?]!
    
    override init() {
        super.init()
        
        self.properties = [:]
    }

    func visitBool(_ p0: String?, p1: Bool) throws {
        self.set(key: p0, value: p1)
    }
    
    func visitNumber(_ p0: String?, p1: Double) throws {
        self.set(key: p0, value: p1)
    }

    func visitObject(_ p0: String?, p1: NINLowLevelClientProps?) throws {
        self.set(key: p0, value: p1)
    }

    func visitObjectArray(_ p0: String?, p1: NINLowLevelClientObjects?) throws {
        self.set(key: p0, value: p1)
    }

    func visit(_ p0: String?, p1: String?) throws {
        self.set(key: p0, value: p1)
    }

    func visitStringArray(_ p0: String?, p1: NINLowLevelClientStrings?) throws {
        self.set(key: p0, value: p1)
    }

    func set(key: String?, value: Any?) {
        guard let key = key else { return }
        properties[key] = value
    }
}