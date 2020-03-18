//
// Copyright (c) 5.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

extension UIColor {
    static var defaultBackgroundButton: UIColor { #colorLiteral(red: 0.2862745098, green: 0.6745098039, blue: 0.9921568627, alpha: 1) }

    static var blueButton: UIColor { #colorLiteral(red: 0.2862745098, green: 0.6745098039, blue: 0.9921568627, alpha: 1) }
    
    static var grayButton: UIColor { #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) }

    static var toastInfoBackground: UIColor { #colorLiteral(red: 0.0, green: 0.54117647, blue: 1.0, alpha: 1) }
}

extension UIColor {
    var toImage: UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1.0, height: 1.0), true, 0.0)
        self.setFill()
        UIRectFill(CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
