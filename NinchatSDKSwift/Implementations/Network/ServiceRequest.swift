//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

public enum HTTPMethod: String {
    case get, post, delete, put
}

protocol ServiceRequest {
    associatedtype ReturnType: Decodable
    associatedtype BodyType: Encodable
    
    var httpMethod: HTTPMethod { get }
    var url: String { get }
    var bodyData: BodyType? { get }
}

extension ServiceRequest {
    var url: String {
        "https://api.ninchat.com/v2/call"
    }
    
    var httpMethod: HTTPMethod {
        .post
    }
    
    var headers: [String:String] {
        ["Accept": "application/json", "Content-Type": "application/json"]
    }
    
    var body: Data? {
        guard let bodyData = self.bodyData else { return nil }
        return try? JSONEncoder().encode(bodyData)
    }
}