//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct Queue {
    let queueID: String
    let name: String
    
    var description: String {
        "Queue ID: \(self.queueID), Name: \(self.name)"
    }
}