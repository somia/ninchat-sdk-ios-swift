//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import MobileCoreServices

struct ChatMessagePayload: Decodable {
    let text: String
    let files: [FileAttributes]?
}

struct FileAttributes: Decodable {
    let id: String
    let attributes: Attributes
    
    enum CodingKeys: String, CodingKey {
        case id = "file_id"
        case attributes = "file_attrs"
    }
}

final class Attributes: Decodable {
    var name: String!
    var type: String!
    var size: Int!
    
    enum CodingKeys: String, CodingKey {
        case name, type, size
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        if let fileType = try? container.decode(String.self, forKey: .type) {
            type = fileType
        } else {
            type = extractType(from: name)
        }
        size = try container.decode(Int.self, forKey: .size)
    }
    
    private func extractType(from name: String) -> String {
        let fileExtension = (name as NSString).pathExtension.lowercased()
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }

}

