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
    var translation: [String:String]? { get }
    var agentAvatar: AnyHashable? { get }
    var agentName: String? { get }
    var userAvatar: AnyHashable? { get }
    var userName: String? { get }
    var noQueueText: String? { get }
    var audienceAutoQueue: String? { get }
    var preAudienceQuestionnaire: [QuestionnaireConfiguration]? { get }
    var postAudienceQuestionnaire: [QuestionnaireConfiguration]? { get }

    init(configuration: [AnyHashable : Any]?, environments: [String]?)
    mutating func override(configuration: NINSiteConfiguration?)
}

struct SiteConfigurationImpl: SiteConfiguration {
    private let configuration: [AnyHashable : Any]?
    private let environments: [String]

    // MARK: - NINSiteConfiguration

    private var _userName: String?
    var userName: String? {
        get {
            if _userName != nil {
                return _userName
            }
            return self.value(for: "userName")
        }
        set {
            _userName = newValue
        }
    }

    // MARK: - SiteConfiguration

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
    var noQueueText: String? {
        self.value(for: "noQueuesText")
    }
    var audienceAutoQueue: String? {
        self.value(for: "audienceAutoQueue")
    }
    var preAudienceQuestionnaire: [QuestionnaireConfiguration]? {
        if let questionnaire = self.value(for: "preAudienceQuestionnaire", ofType: Array<[String: AnyHashable]>.self) {
            return AudienceQuestionnaire(from: questionnaire).questionnaireConfiguration
        }
        return nil
    }
    var postAudienceQuestionnaire: [QuestionnaireConfiguration]? {
        if let questionnaire = self.value(for: "postAudienceQuestionnaire", ofType: Array<[String: AnyHashable]>.self) {
            return AudienceQuestionnaire(from: questionnaire).questionnaireConfiguration
        }
        return nil
    }

    init(configuration: [AnyHashable : Any]?, environments: [String]?) {
        self.configuration = configuration ?? [:]
        self.environments = environments ?? []
    }

    mutating func override(configuration: NINSiteConfiguration?) {
        guard let configuration = configuration else { return }
        self.userName = configuration.userName
    }
}

extension SiteConfigurationImpl {
    private func value<T>(for key: String, ofType type: T.Type = T.self) -> T? {
        guard let configuration = configuration as? [String:Any] else { return nil }

        /// Use given environments first, if any
        if let value = self.environments.compactMap({ (configuration[$0] as? [String:Any])?[key] }).first as? T {
            return value
        }

        /// Return value from default environment
        return (configuration["default"] as? [String : Any])?[key] as? T
    }
}
