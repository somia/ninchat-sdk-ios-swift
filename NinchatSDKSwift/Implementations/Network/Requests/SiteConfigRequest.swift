//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import AnyCodable

struct SiteConfigRequest: ServiceRequest {
    typealias ReturnType = AnyCodable
    typealias BodyType = Empty
    
    private(set) var url: String
    private(set) var httpMethod: HTTPMethod = .get
    private(set) var bodyData: BodyType?
    
    init(serverAddress: String, configKey: String) {
        self.url = "https://\(serverAddress)/config/\(configKey)"
    }
}