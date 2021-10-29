//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension UIImageView {
    func image(from url: String?, completion: ((Data?, Error?) -> Void)? = nil, defaultImage: UIImage) {
        self.image(from: URL(string: url ?? ""), completion: completion, defaultImage: defaultImage)
    }
    
    func image(from url: URL?, completion: ((Data?, Error?) -> Void)? = nil, defaultImage: UIImage) {
        url?.fetchImage { [weak self] data, error in
            DispatchQueue.main.async() {
                if let data = data {
                    self?.image = UIImage(data: data)
                } else if error != nil {
                    self?.image = defaultImage
                }
                completion?(data, error)
            }
        }
    }

    func fetchImage(from url: URL?, completion: ((Data?, Error?) -> Void)? = nil) {
        url?.fetchImage(completion: completion)
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
