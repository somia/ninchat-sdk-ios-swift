//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol NINChatSessionManagerClosureHandler {
    func bind(action id: Int, closure: @escaping ((Error?) -> Void))
    func unbind(action id: Int)
}

extension NINChatSessionManagerImpl: NINChatSessionManagerClosureHandler {
    internal func bind(action id: Int, closure: @escaping ((Error?) -> Void)) {
        if actionBoundClosures.keys.filter({ $0 == id }).count > 0 { return }
        actionBoundClosures[id] = closure
        
        if self.onActionID == nil {
            self.onActionID = { [weak self] id, error in
                let targetClosure = self?.actionBoundClosures.filter({ $0.key == id }).first?.value
                targetClosure?(error)
            }
        }
    }
    internal func unbind(action id: Int) {
        if actionBoundClosures.keys.filter({ $0 == id }).count == 0 { return }
        actionBoundClosures.removeValue(forKey: id)
    }
}
