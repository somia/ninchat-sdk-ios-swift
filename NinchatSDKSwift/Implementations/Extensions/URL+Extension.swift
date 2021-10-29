//
// Copyright (c) 27.1.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

extension URL {
    func fetchImage(completion: ((Data?, Error?) -> Void)? = nil) {
        URLSession.shared.dataTask(with: URLRequest(url: self, cachePolicy: .returnCacheDataElseLoad)) { (data: Data?, response: URLResponse?, error: Error?) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil
            else {
                completion?(nil, error); return
            }
            completion?(data, nil)
        }.resume()
    }
}
