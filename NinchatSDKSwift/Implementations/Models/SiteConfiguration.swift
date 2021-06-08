//
// Copyright (c) 11.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum QuestionnaireStyle: String {
    case conversation
    case form
}

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
    var hideTitlebar: Bool { get }
    var audienceQuestionnaireAvatar: AnyHashable? { get }
    var audienceQuestionnaireUserName: String? { get }
    var audienceRegisteredText: String? { get }
    var audienceRegisteredClosedText: String? { get }
    var preAudienceQuestionnaireStyle: QuestionnaireStyle { get }
    var preAudienceQuestionnaireDictionary: Array<[String:AnyHashable]>? { get }
    var preAudienceQuestionnaire: [QuestionnaireConfiguration]? { get }
    var postAudienceQuestionnaireStyle: QuestionnaireStyle { get }
    var postAudienceQuestionnaireDictionary: Array<[String:AnyHashable]>? { get }
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
    var hideTitlebar: Bool {
        self.value(for: "hideTitlebar") ?? false
    }

    var audienceQuestionnaireAvatar: AnyHashable? {
        self.value(for: "questionnaireAvatar")
    }
    var audienceQuestionnaireUserName: String? {
        self.value(for: "questionnaireName")
    }
    var audienceRegisteredText: String? {
        self.value(for: "audienceRegisteredText")
    }
    var audienceRegisteredClosedText: String? {
        self.value(for: "audienceRegisteredClosedText")
    }

    // MARK: - PreAudience Questionnaire
    var preAudienceQuestionnaireStyle: QuestionnaireStyle {
        guard let style = self.value(for: "preAudienceQuestionnaireStyle", ofType: String.self), !style.isEmpty
            else { return .form }
        
        return QuestionnaireStyle(rawValue: style.lowercased()) ?? .form
    }
    var preAudienceQuestionnaireDictionary: Array<[String:AnyHashable]>? {
        self.value(for: "preAudienceQuestionnaire")
    }
    var preAudienceQuestionnaire: [QuestionnaireConfiguration]? {
        if let questionnaire = self.preAudienceQuestionnaireDictionary {
            return AudienceQuestionnaire(from: questionnaire).questionnaireConfiguration
        }
        return nil
    }

    // MARK: - PostAudience Questionnaire
    var postAudienceQuestionnaireStyle: QuestionnaireStyle {
        guard let style = self.value(for: "postAudienceQuestionnaireStyle", ofType: String.self), !style.isEmpty
            else { return .form }
        
        return QuestionnaireStyle(rawValue: style.lowercased()) ?? .form
    }
    var postAudienceQuestionnaireDictionary: Array<[String : AnyHashable]>? {
        self.value(for: "postAudienceQuestionnaire")
    }
    var postAudienceQuestionnaire: [QuestionnaireConfiguration]? {
        if let questionnaire = self.postAudienceQuestionnaireDictionary {
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
        var environments = self.environments

        /// Insert "default" to the beginning of given environments
        if !environments.contains("default") {
            environments.insert("default", at: 0)
        }

        /// Lookup should be done from the last env to the first one
        environments.reverse()
        debugger("Loading keys from environments: \(environments)")

        /// Start the lookup
        return environments.compactMap({ (configuration[$0] as? [String:Any])?[key] as? T }).first
    }
}
