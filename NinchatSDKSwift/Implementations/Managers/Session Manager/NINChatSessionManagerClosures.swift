//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

protocol NINChatSessionManagerClosureHandler {
    func bind(action id: Int, closure: @escaping ((Error?) -> Void))
    func unbine(action id: Int)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerClosureHandler {
    internal func bind(action id: Int, closure: @escaping ((Error?) -> Void)) {
        if actionBindedClosures.keys.filter({ $0 == id }).count > 0 { return }
        actionBindedClosures[id] = closure
        
        if self.onActionID == nil {
            self.onActionID = { [weak self] id, error in
                let targetClosure = self?.actionBindedClosures.filter({ $0.key == id }).first?.value
                targetClosure?(error)
            }
        }
    }
    internal func unbine(action id: Int) {
        if actionBindedClosures.keys.filter({ $0 == id }).count == 0 { return }
        actionBindedClosures.removeValue(forKey: id)
    }
}