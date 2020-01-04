//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum Element: String, Decodable {
    case select
    case button
}

struct ComposeMessagePayload: Decodable {
    let element: Element?
}
