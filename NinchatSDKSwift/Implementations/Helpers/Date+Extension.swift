//
// Copyright (c) 13.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct DateCompare {
    let year: Int?
    let month: Int?
    let day: Int?
    let hour: Int?
    let minute: Int?
    let second: Int?
    
    init(diff: DateComponents) {
        self.year = diff.year
        self.month = diff.month
        self.day = diff.day
        self.hour = diff.hour
        self.minute = diff.minute
        self.second = diff.second
    }
}

extension Date {
    static func -(recent: Date, previous: Date) -> DateCompare {
        let diff = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: previous, to: recent)
        return DateCompare(diff: diff)
    }
}
