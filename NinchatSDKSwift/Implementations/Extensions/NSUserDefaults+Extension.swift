//
// Copyright (c) 10.11.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

extension UserDefaults {
    enum Keys: String {
        case metadata
    }

    static func save<T:Any>(_ value: T, key: Keys) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }

    static func load<T:Any>(forKey key: Keys) -> T? {
        UserDefaults.standard.value(forKey: key.rawValue) as? T
    }

    static func remove(forKey key: Keys) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
}
