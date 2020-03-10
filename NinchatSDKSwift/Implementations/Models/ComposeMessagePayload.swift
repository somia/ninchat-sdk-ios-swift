//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum Element: String, Codable {
    case select
    case button
}

// MARK: - ComposeMessagePayload
struct ComposeMessagePayload: Codable {
    let payloadClass, link, id, label, name: String?
    let element: Element
    let options: [Option]?
    
    enum CodingKeys: String, CodingKey {
        case payloadClass = "class"
        case element, id, label, name, options
        case link = "href"
    }
}

// MARK: - Option
struct Option: Codable {
    let label, value: String
}
