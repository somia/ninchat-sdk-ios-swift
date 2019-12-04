//
//  NINChatExceptions.swift
//  NinchatSDK
//
//  Created by Hassan Shahbazi on 22.11.2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

import Foundation

public enum NINChatExceptions: Error {
    case apiNotStarted
    
    public var localizedDescription: String {
        switch self {
        case .apiNotStarted:
            return "NINChat API has not been started; call -startWithCallback first"
        }
    }
}
