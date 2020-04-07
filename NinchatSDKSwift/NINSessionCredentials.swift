//
// Copyright (c) 3.4.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

/* Stores Session credentials */
public struct NINSessionCredentials: Codable {
    /* User identification */
    let userID: String

    /* User authentication */
    let userAuth: String

    /* Corresponded session_id (optional) */
    let sessionID: String?


    /* Initiate the model using `NINLowLevelClientProps` received from server */
    init(params: NINLowLevelClientProps) throws {
        if case let .failure(error) = params.userID { throw error }
        if case let .failure(error) = params.userAuth { throw error }
        if case let .failure(error) = params.sessionID { throw error }

        self.init(userID: params.userID.value, userAuth: params.userAuth.value, sessionID: params.sessionID.value)
    }

    /* Initiate the model using cached/saved values */
    public init(userID: String, userAuth: String, sessionID: String?) {
        self.userID = userID
        self.userAuth = userAuth
        self.sessionID = sessionID
    }
}