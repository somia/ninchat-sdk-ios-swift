//
// Copyright (c) 11.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

protocol SiteConfiguration  {
    var welcome: String? { get }
    var motd: String? { get }
    var inQueue: String? { get }
    var sendButtonTitle: String? { get }
    var confirmDialogTitle: String? { get }
    var audienceRealm: String? { get }
    var audienceQueues: [String]? { get }
    var username: String? { get }
    var translation: [String:String]? { get }
    var agentAvatar: AnyHashable? { get }
    var agentName: String? { get }
    var userAvatar: AnyHashable? { get }
    var userName: String? { get }
    
    init(configuration: [AnyHashable : Any]?, environments: [String]?)
}

struct SiteConfigurationImpl: SiteConfiguration {
    private let configuration: [AnyHashable : Any]?
    private let environments: [String]

    init(configuration: [AnyHashable : Any]?, environments: [String]?) {
        self.configuration = configuration ?? [:]
        self.environments = environments ?? []
    }
    
    var welcome: String? {
        self.value(for: "welcome")
    }
    
    var motd: String? {
        self.value(for: "motd")
    }
    
    var inQueue: String? {
        self.value(for: "inQueueText")
    }
    
    var sendButtonTitle: String? {
        self.value(for: "sendButtonText")
    }
    
    var confirmDialogTitle: String? {
        self.value(for: "closeConfirmText")
    }
    
    var audienceRealm: String? {
        self.value(for: "audienceRealmId")
    }
    
    var audienceQueues: [String]? {
        self.value(for: "audienceQueues")
    }
    
    var username: String? {
        self.value(for: "userName")
    }
    
    var translation: [String:String]? {
        self.value(for: "translations")
    }
    
    var agentAvatar: AnyHashable? {
        self.value(for: "agentAvatar")
    }
    
    var agentName: String? {
        self.value(for: "agentName")
    }
    
    var userAvatar: AnyHashable? {
        self.value(for: "userAvatar")
    }
    
    var userName: String? {
        self.value(for: "userName")
    }
}

extension SiteConfigurationImpl {
    private func value<T>(for key: String) -> T? {
        guard let configuration = configuration as? [String : Any] else { return nil }
        
        if let value = self.environments.compactMap({ (configuration[$0] as? [String : Any])?[key] }).first as? T {
            return value
        }
        return (configuration["default"] as? [String : Any])?[key] as? T
    }
}