//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

public enum NINChatExceptions: Error {
    case mainThread
    case apiNotStarted
    
    public var localizedDescription: String {
        switch self {
        case .mainThread:
            return "The method should be called in the main thread"
        case .apiNotStarted:
            return "NINChat API has not been started; call `-start` first"
        }
    }
}
