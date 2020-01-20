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
    
    var confirmDialogTitle: String? {
        self.value(forKey: "closeConfirmText") as? String
    }
        
    var audienceRealm: String? {
        self.value(forKey: "audienceRealmId") as? String
    }
    
    var audienceQueues: [String]? {
        self.value(forKey: "audienceQueues") as? [String]
    }
    
    var username: String? {
        self.value(forKey: "userName") as? String
    }
    
    var translation: [String:String]? {
        self.value(forKey: "translations") as?  [String:String]
    }
    
    var agentAvatar: String? {
        self.value(forKey: "agentAvatar") as? String
    }
    
    var agentName: String? {
        self.value(forKey: "agentName") as? String
    }
    
    var userAvatar: String? {
        self.value(forKey: "userAvatar") as? String
    }
    
    var userName: String? {
        self.value(forKey: "userName") as? String
    }
}
