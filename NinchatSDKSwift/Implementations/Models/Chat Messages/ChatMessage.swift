//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol ChatMessage: Codable {
    /** Message timestamp. */
    var timestamp: Date { get }

    /** Message ID. */
    var messageID: String { get }
}
