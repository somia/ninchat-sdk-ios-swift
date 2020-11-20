//
// Copyright (c) 1.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

final class NinchatSDKSwiftServerQuestionnaireTests: XCTestCase {
    private let sessionManager = Session.Manager

    func test_0_registerAnswers() {
        let expect = self.expectation(description: "Expected to register audience answers to the queue's statistics")

        sessionManager.updateSecureMetadata()
        sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: nil) { error in
            XCTAssertNil(error)
            try! self.sessionManager.openSession { credentials, canResume, error in
                XCTAssertNil(error)
                XCTAssertNotNil(credentials)

                try! self.sessionManager.list(queues: self.sessionManager.siteConfiguration.audienceQueues) { error in
                    XCTAssertNil(error)

                    guard let answers = self.sessionManager.audienceMetadata else { XCTFail("Unable to get audience metadata"); return }
                    answers.set(value: NINLowLevelClientProps.initiate(preQuestionnaireAnswers: ["question":"answer"]), forKey: "pre_answers")

                    try! self.sessionManager.registerQuestionnaire(queue: Session.suiteQueue, answers: answers) { error in
                        XCTAssertNil(error)
                        expect.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 15.0)
    }
}

private extension NINChatSessionManagerImpl {
    func updateSecureMetadata() {
        NINLowLevelClientProps.saveMetadata(Session.secureMetadata)
    }
}
