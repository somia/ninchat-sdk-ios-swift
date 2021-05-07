//
// Copyright (c) 5.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

private final class BundlePathIdentifier {}

extension Bundle {
    static var SDKBundle: Bundle? {
        let classBundle = Bundle(for: BundlePathIdentifier.self)
        guard let bundleURL = classBundle.url(forResource: "NinchatSwiftSDKUI", withExtension: "bundle") else {
            return classBundle
        }
        return Bundle(url: bundleURL)
    }
}
