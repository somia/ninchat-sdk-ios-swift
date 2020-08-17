//
// Copyright (c) 30.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

extension Array where Element==Int {
    func decodeAndPerform<T:Decodable>(onPayload payload: NINLowLevelClientPayload, type: T.Type, successClosure: @escaping (T) -> Void) throws {
        try self.compactMap({ index -> Data? in
                    payload.get(index)
                })
                .map({ data -> NINResult<T> in
                    data.decode()
                })
                .map({ result -> (T?, Error?) in
                    switch result {
                    case .success(let message): return (message, nil)
                    case .failure(let error): return (nil, error)
                    }
                })
                .compactMap({ (tuple: (T?, Error?)) -> T? in
                    if let error = tuple.1 { throw error }
                    return tuple.0
                })
                .forEach({ (message: T) in
                    successClosure(message)
                })
    }
}
