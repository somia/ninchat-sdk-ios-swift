//
// Copyright (c) 7.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension CALayer {
    func apply(_ layer: CALayer, force: Bool = true) {
        var count = UInt32()
        guard let layerClassProps: UnsafeMutablePointer <objc_property_t> = class_copyPropertyList(CALayer.self, &count) else {
            fatalError("unable to fetch class properties")
        }
        
        if self.name == LAYER_NAME, !force {
            /// the layer was set before, skip overwriting it
            /// unless it is forced (e.g. button selected)
            return
        }
        
        (0..<count)
            .map({ String(cString: property_getName(layerClassProps[Int($0)])) })
            .compactMap({ ($0, layer.value(forKey: $0)) })
            .filter({ $0.1 != nil }) /// skip setting nil values
            .forEach { (key, value) in
                self.setValue(value, forKey: key)
        }
    }
}
