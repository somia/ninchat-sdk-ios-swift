//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct AvatarConfig {
    let show: Bool
    let imageOverrideURL: String?
    let nameOverride: String
    
    init(avatar: AnyHashable?, name: String?) {
        self.imageOverrideURL = avatar as? String
        self.show = (avatar as? Bool) ?? true
        self.nameOverride = name ?? ""
    }
}