//
// Copyright (c) 14.4.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct CloseSession: ServiceRequest {
    typealias ReturnType = Empty
    typealias BodyType = CloseSessionBody

    private(set) var url: String
    private(set) var httpMethod: HTTPMethod = .post
    private(set) var bodyData: BodyType?

    init(url: String, credentials: NINSessionCredentials, siteSecret: String?) {
        self.url = "https://\(url)/v2/call"
        self.bodyData = CloseSessionBody(credentials: credentials, siteSecret: siteSecret)
    }

    struct CloseSessionBody: Codable {
        let action: String = "close_session"
        let sessionID: String?
        let siteSecret: String?

        init(credentials: NINSessionCredentials, siteSecret: String?) {
            self.sessionID = credentials.sessionID
            self.siteSecret = siteSecret
        }

        enum CodingKeys: String, CodingKey {
            case action
            case sessionID = "session_id"
            case siteSecret = "site_secret"
        }
    }
}