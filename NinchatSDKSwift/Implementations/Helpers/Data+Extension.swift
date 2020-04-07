//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

public enum NINResult<Value> {
    case success(Value)
    case failure(Error)

    var value: Value {
        if case let .success(value) = self {
            return value
        }
        fatalError("Error in getting value: \(self)")
    }
}

extension Data {
    func decode<T: Decodable>() -> NINResult<T> {
        do {
            return .success(try JSONDecoder().decode(T.self, from: self))
        } catch {
            return .failure(error)
        }
    }
}
