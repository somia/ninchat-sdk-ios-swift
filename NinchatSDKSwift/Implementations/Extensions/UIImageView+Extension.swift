//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension UIImageView {
    func image(from url: String?, completion: ((Data) -> Void)? = nil) {
        guard let urlStr = url  else { return }
        self.image(from: URL(string: urlStr), completion: completion)
    }
    
    func image(from url: URL?, completion: ((Data) -> Void)? = nil) {
        guard let url = url else { return }
    
        URLSession.shared.dataTask(with: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)) { (data: Data?, response: URLResponse?, error: Error?) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
        
            DispatchQueue.main.async() {
                self.image = image
                completion?(data)
            }
        }.resume()
    }

    func fetchImage(from url: URL?, completion: ((Data) -> Void)? = nil) {
        guard let url = url else { return }
        URLSession.shared.dataTask(with: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)) { (data: Data?, response: URLResponse?, error: Error?) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil
            else { return }

            DispatchQueue.main.async() { completion?(data) }
        }.resume()
    }

    var tint: UIColor? {
        set {
            self.image = self.image?.withRenderingMode(.alwaysTemplate)
            self.tintColor = newValue
        }
        get {
            self.tintColor
        }
    }
}
