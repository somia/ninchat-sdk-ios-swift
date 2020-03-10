//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

final class NINFileInfo {
    var fileID: String!
    var name: String!
    var mimeType: String!
    var size: Int!
    var url: String?
    var urlExpiry: Date?
    var aspectRatio: Double?
    
    // MARK: - Initializer
    
    init(fileID: String, name: String, mimeType: String, size: Int, url: String? = nil, urlExpiry: Date? = nil) {
        self.fileID = fileID
        self.name = name
        self.mimeType = mimeType
        self.size = size
        self.url = url
        self.urlExpiry = urlExpiry
    }
    
    // MARK: - Getters
    
    var description: String {
        return "ID: \(String(describing: fileID)), mimeType: \(String(describing: mimeType)), size: \(String(describing: size))"
    }
    
    var isImage: Bool {
        return self.mimeType.hasPrefix("image/")
    }
    
    var isVideo: Bool {
        return self.mimeType.hasPrefix("video/")
    }
    
    var isPDF: Bool {
        return self.mimeType == "application/pdf"
    }
    
    // MARK: - Functions
    
    func updateInfo(session: NINChatSessionAttachment, completion: @escaping ((Error?, _ didRefreshNetwork: Bool) -> Void)) {
        /// The URL must not expire within the next 15 minutes
        let comparisonDate = Date(timeIntervalSinceNow: -(15*60))
        
        guard self.url == nil || self.urlExpiry == nil || self.urlExpiry?.compare(comparisonDate) == .orderedAscending else {
            debugger("No need to update file, it is up to date.")
            completion(nil, false)
            return
        }
        
        debugger("Must update file info; call describe_file")
        do {
            try session.describe(file: self.fileID) { [weak self] error, fileInfo in
                if let error = error {
                    completion(error, false)
                } else if let info = fileInfo {
                    let file = FileInfo(json: info)
                    
                    self?.url = file.url
                    self?.urlExpiry = file.urlExpiry
                    self?.aspectRatio = file.aspectRatio
                    completion(nil, true)
                }
            }
        } catch {
            completion(error, false)
        }
    }
    
    // MARK: - Codable object
    
    struct FileInfo: Codable {
        let url: String?
        let urlExpiry: Date?
        let aspectRatio: Double?
        
        init(json: [String:Any]) {
            self.url = json["url"] as? String
            self.urlExpiry = json["urlExpiry"] as? Date
            self.aspectRatio = json["aspectRatio"] as? Double
        }
    }
}
