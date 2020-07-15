//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum QueuePermissionType: String {
    case member
}

struct Queue {
    let queueID: String
    let name: String
    let isClosed: Bool
    let permissions: QueuePermissions
}

struct QueuePermissions {
    let upload: Bool
    let video: Bool = true
}
