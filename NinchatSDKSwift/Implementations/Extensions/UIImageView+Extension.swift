//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension UIImageView {
    func image(from url: String?, completion: ((Data) -> Void)? = nil) {
        self.image(from: URL(string: url ?? ""), completion: completion)
    }
    
    func image(from url: URL?, completion: ((Data) -> Void)? = nil) {
        url?.fetchImage { [weak self] data in
            DispatchQueue.main.async() {
                self?.image = UIImage(data: data)
                completion?(data)
            }
        }
    }

    func fetchImage(from url: URL?, completion: ((Data) -> Void)? = nil) {
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
