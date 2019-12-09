//
//  String+SiteConfiguration.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 5.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
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
}
