//
// Copyright (c) 5.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import NinchatSDK

extension NINSiteConfiguration {
    var welcome: String? {
        self.value(forKey: "welcome") as? String
    }
    
    var motd: String? {
        self.value(forKey: "motd") as? String
    }
    
    var inQueue: String? {
        self.value(forKey: "inQueueText") as? String
    }
    
    var sendButtonTitle: String? {
        self.value(forKey: "sendButtonText") as? String
    }
}
