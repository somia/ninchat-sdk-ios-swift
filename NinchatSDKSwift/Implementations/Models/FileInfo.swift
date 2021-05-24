//
// Copyright (c) 30.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

final class FileInfo: Codable {
    var fileID: String!
    var name: String!
    var mimeType: String!
    var size: Int!
    var url: String?
    var thumbnailUrl: String?
    var urlExpiry: Date?
    var aspectRatio: Double?
    
    // MARK: - Initializer
    
    init(fileID: String, name: String, mimeType: String, size: Int, url: String? = nil, thumbnailUrl: String? = nil, urlExpiry: Date? = nil) {
        self.fileID = fileID
        self.name = name
        self.mimeType = mimeType
        self.size = size
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.urlExpiry = urlExpiry
    }
    
    // MARK: - Getters
    
    var description: String {
        "ID: \(String(describing: fileID)), mimeType: \(String(describing: mimeType)), size: \(String(describing: size))"
    }
    
    var isImage: Bool {
        self.mimeType.hasPrefix("image/")
    }
    
    var isVideo: Bool {
        self.mimeType.hasPrefix("video/")
    }
    
    var isPDF: Bool {
        self.mimeType == "application/pdf"
    }

    var fileExpired: Bool {
        self.url == nil || self.urlExpiry == nil || self.urlExpiry?.compare(Date(timeIntervalSinceNow: -(15*60))) == .orderedAscending
    }

    // MARK: - Functions
    
    func updateInfo(session: NINChatSessionAttachment?, completion: @escaping (Error?, _ didRefreshNetwork: Bool) -> Void) {
        /// The URL must not expire within the next 15 minutes
        guard fileExpired else {
            debugger("No need to update file, it is up to date. \(self.name ?? "")")
            completion(nil, false)
            return
        }

        debugger("Must update file info; call describe_file with id: \(self.fileID ?? "") and name: \(self.name ?? "")")
        do {
            try session?.describe(file: self.fileID) { [weak self] error, fileInfo in
                guard let `self` = self else { return }
                debugger("described file with id: \(self.fileID ?? "nil") and name: \(self.name ?? "")")

                if let error = error {
                    completion(error, false)
                } else if let info = fileInfo {
                    self.url = info["url"] as? String
                    self.urlExpiry = info["urlExpiry"] as? Date
                    self.thumbnailUrl = info["thumbnailUrl"] as? String
                    self.aspectRatio = info["aspectRatio"] as? Double
                    completion(nil, true)
                }
            }
        } catch {
            completion(error, false)
        }
    }
}
