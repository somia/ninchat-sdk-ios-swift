//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct ChannelUser: Equatable {
    let userID: String
    let realName: String
    let displayName: String
    let iconURL: String?
    let guest: Bool
}

// MARK: - Equatable
extension ChannelUser {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.userID == rhs.userID
    }
}