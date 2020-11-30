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
    
    static var ninchat: UserDefaults {
        UserDefaults(suiteName: "com.ninchat.sdk.swift")!
    }
    
    static func save<T:Any>(_ value: T, key: Keys) {
        UserDefaults.ninchat.set(value, forKey: key.rawValue)
        UserDefaults.ninchat.synchronize()
    }

    static func load<T:Any>(forKey key: Keys) -> T? {
        migrate(key: key)
        return UserDefaults.ninchat.value(forKey: key.rawValue) as? T
    }

    static func remove(forKey key: Keys) {
        UserDefaults.ninchat.removeObject(forKey: key.rawValue)
    }
    
    // MARK: - Helper
    
    /// migrate value from 'standard' to 'ninchat'
    private static func migrate(key: Keys) {
        let value = UserDefaults.standard.value(forKey: key.rawValue)
        if value == nil { return }
        
        self.save(value, key: key)
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
}
