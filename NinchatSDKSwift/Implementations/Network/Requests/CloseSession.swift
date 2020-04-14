//
// Copyright (c) 14.4.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct CloseSession: ServiceRequest {
    typealias ReturnType = Empty
    typealias BodyType = CloseSessionBody

    private(set) var url: String = "https://api.luupi.net/v2/poll"
    private(set) var httpMethod: HTTPMethod = .post
    private(set) var bodyData: BodyType?

    init(credentials: NINSessionCredentials, siteSecret: String? = nil) {
        bodyData = CloseSessionBody(credentials: credentials, siteSecret: siteSecret)
    }

    struct CloseSessionBody: Codable {
        let action: String = "close_session"
        let userID: String
        let userAuth: String
        let sessionID: String?
        let siteSecret: String?

        init(credentials: NINSessionCredentials, siteSecret: String?) {
            self.userID = credentials.userID
            self.userAuth = credentials.userAuth
            self.sessionID = credentials.sessionID
            self.siteSecret = siteSecret
        }

        enum CodingKeys: String, CodingKey {
            case action
            case userID = "user_id"
            case userAuth = "user_auth"
            case sessionID = "session_id"
            case siteSecret = "site_secret"
        }
    }
}