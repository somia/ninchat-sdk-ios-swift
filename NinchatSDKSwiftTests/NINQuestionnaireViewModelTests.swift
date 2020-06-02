//
// Copyright (c) 2.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

final class NINQuestionnaireViewModelTests: XCTestCase {
    private lazy var answers: NINLowLevelClientProps = {
        NINLowLevelClientProps.initiate(preQuestionnaireAnswers: ["pre-answer1": "1", "pre-answer2": "2"])
    }()
    private var session: NINChatSessionManagerImpl!
    private var viewModel: NINQuestionnaireViewModelImpl?

    override func setUp() {
        super.setUp()
        let siteConfiguration = SiteConfigurationImpl(configuration: try! openAsset(forResource: "site-configuration-mock"), environments: ["default"])
        self.session = NINChatSessionManagerImpl(session: nil, serverAddress: "", audienceMetadata: self.answers, configuration: nil)
        self.session.setSiteConfiguration(siteConfiguration)

        self.viewModel = NINQuestionnaireViewModelImpl(sessionManager: session)
    }

    func test_00_initialization() {
        XCTAssertNotNil(self.session)
        XCTAssertNotNil(self.viewModel)
    }

    func test_10_preAnswersInitiated() {
        XCTAssertNotEqual(self.viewModel?.answers, [:])
        XCTAssertEqual(self.viewModel?.answers["pre-answer1"], "1")
    }
}
