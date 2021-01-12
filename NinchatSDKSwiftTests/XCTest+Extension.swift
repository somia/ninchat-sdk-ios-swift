//
// Copyright (c) 2.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

extension XCTest {
    func openAsset(forResource name: String, ofType type: String = "json") throws -> [String:AnyHashable]? {
        let bundle = Bundle(for: QuestionnaireParserTests.self)
        if let path = bundle.path(forResource: name, ofType: type) {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            return jsonResult as? [String:AnyHashable]
        }
        return nil
    }
}

extension AudienceQuestionnaire {
    init(from configuration: [AnyHashable : Any]?, for key: String) {
        self.init(from: nil)

        guard let configuration = configuration, let questionnaireConfigurations = configuration[key] as? Array<[String:AnyHashable]> else { return }
        questionnaireConfiguration = questionnaireConfigurations.reduce(into: []) { (result: inout [QuestionnaireConfiguration], dictionary: [String: AnyHashable]) in
            guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return }
            do {
                let questionnaire = try JSONDecoder().decode(QuestionnaireConfiguration.self, from: data)
                result.append(questionnaire)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}

extension NINChatSessionManagerImpl {
    func setSiteConfiguration(_ config: SiteConfiguration) {
        self.siteConfiguration = config
    }
}
