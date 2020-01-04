//
// Copyright (c) 22.11.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

public enum NINExceptions: Error {
    case mainThread
    case apiNotStarted
        
    public var localizedDescription: String {
        switch self {
        case .mainThread:
            return "The method should be called in the main thread"
        case .apiNotStarted:
            return "NINChat API has not been started; call -startWithCallback first"
        }
    }
}

public enum NINSessionExceptions: Error {
    case hasActiveSession
    case noActiveSession
    case noActiveChannel
    case noParamChannel
    case hasActiveChannel
    case noActiveQueue
    case noActiveUserID
    case invalidRealmConfiguration
    case invalidServerAddress
    
    public var localizedDescription: String {
        switch self {
        case .hasActiveSession:
            return "Existing chat session found"
        case .noActiveSession:
            return "No chat session"
        case .noActiveChannel:
            return "No active channel"
        case .noParamChannel:
            return "Channel ID must exist"
        case .hasActiveChannel:
            return "Already have current queue"
        case .noActiveQueue:
            return "Must have current queue"
        case .noActiveUserID:
            return "Must have user id"
        case .invalidRealmConfiguration:
            return "Could not find valid realm id in the site configuration"
        case .invalidServerAddress:
            return "Must have server address"
        }
    }
}
