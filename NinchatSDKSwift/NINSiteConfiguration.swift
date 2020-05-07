//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

public protocol NINSiteConfiguration  {
    var userName: String? { get }
    init(userName: String?)
}

public struct NINSiteConfigurationImpl: NINSiteConfiguration {
    public var userName: String?

    public init(userName: String?) {
        self.userName = userName
    }
}