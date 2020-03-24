//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum Result<Value> {
    case success(Value)
    case failure(Error)
}

extension Data {
    func decode<T: Decodable>() -> Result<T> {
        do {
            return .success(try JSONDecoder().decode(T.self, from: self))
        } catch {
            return .failure(error)
        }
    }
}
