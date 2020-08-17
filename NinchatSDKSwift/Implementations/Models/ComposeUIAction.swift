//
// Copyright (c) 08.07.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum ComposeUIActionType: String, Codable {
    case click
}

struct ComposeUIAction: Codable {
    let action: ComposeUIActionType
    let target: ComposeContent
}
