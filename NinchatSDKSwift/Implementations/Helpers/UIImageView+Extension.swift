//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import Kingfisher

extension UIImageView {
    func fetchImage(_ urlString: String, placeholder: UIImage? = nil, completion: (() -> Void)? = nil) {
        guard let url = URL(string: urlString) else { return }
        
        self.kf.setImage(with: url, placeholder: placeholder, completionHandler: { image, error, type, url in
            completion?()
        })
    }
}
