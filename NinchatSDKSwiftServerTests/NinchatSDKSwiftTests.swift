//
// Copyright (c) 13.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import Foundation
@testable import NinchatSDKSwift

/**
  * This test suite is not a part of 'NinchatSDKSwift' even though they are coupled.
  * This is because tests *must* be run only in a supervised situation occasionally,
  * since the server's responses still are not automated.
  *
  * The suite will be updated once we figure out an approach to
  * make all the server's responses automated.
  *
  * The suite is available on repository, however, credentials are kept privately.
  * To run tests against your server, import a .plist to the test target containing at least the following keys:
  *     - server
  *     - configKey
  *     - queue
  *     - queue-closed
*/

struct Configuration: Codable {
    let server: String
    let secret: String? /// Optional
    let configKey: String
    let queue: String
    let closedQueue: String? /// Optional

    enum CodingKeys: String, CodingKey {
        case server, secret, configKey, queue
        case closedQueue = "queue-closed"
    }
}

final class Session {
    static var Manager = NINChatSessionManagerImpl(session: nil, serverAddress: serverAddress, siteSecret: siteSecret)
    
    private static var configuration: Configuration {
        if let path = Bundle(for: self).url(forResource: "Secrets", withExtension: "plist"), let data = try? Data(contentsOf: path) {
            return try! PropertyListDecoder().decode(Configuration.self, from: data)
        }
        fatalError("config file not found. Import your file configurations as a .plist file to the workspace")
    }

    static var serverAddress: String {
        configuration.server
    }
    static var siteSecret: String? {
        configuration.secret
    }
    static var configurationKey: String {
        configuration.configKey
    }
    static var suiteQueue: String {
        configuration.queue
    }
    static var closedQueue: String? {
        configuration.closedQueue
    }
}