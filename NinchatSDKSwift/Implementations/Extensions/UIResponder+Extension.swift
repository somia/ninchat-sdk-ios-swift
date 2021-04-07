//
// Copyright (c) 7.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol HasCustomLayer {
    func applyLayerOverride(view: UIView)
}
extension HasCustomLayer where Self:UIResponder {
    func applyLayerOverride(view: UIView) {
        view.layer.sublayers?.filter({ $0.name == LAYER_NAME }).forEach({
            $0.frame = view.bounds
        })
    }
}
