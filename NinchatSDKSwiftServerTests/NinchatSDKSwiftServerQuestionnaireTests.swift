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

                try! self.sessionManager.describe(queuesID: self.sessionManager.siteConfiguration.audienceQueues) { error in
                    XCTAssertNil(error)

                    guard let answers = self.sessionManager.audienceMetadata else { XCTFail("Unable to get audience metadata"); return }
                    answers.set(value: NINLowLevelClientProps.initiate(preQuestionnaireAnswers: ["question":"answer"]), forKey: "pre_answers")

                    try! self.sessionManager.registerAudience(queue: Session.suiteQueue, answers: answers) { error in
                        XCTAssertNil(error)
                        expect.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 15.0)
    }

    func test_1_describeQueues() {
        var viewModel: NINQuestionnaireViewModel!
        let expect = self.expectation(description: "Expected to describe all queues mentioned in the configurations")

        sessionManager.updateSecureMetadata()
        sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: nil) { error in
            XCTAssertNil(error)

            try! self.sessionManager.openSession { _, _, error in
                XCTAssertNil(error)

                try! self.sessionManager.describe(queuesID: self.sessionManager.siteConfiguration.audienceQueues) { error in
                    XCTAssertNil(error)
                    XCTAssertFalse(self.sessionManager.queues.contains(where: { $0.queueID == "7s1gafig00ofg" }))
                    XCTAssertFalse(self.sessionManager.queues.contains(where: { $0.queueID == "76nr0l4m00t5" }))

                    viewModel = NINQuestionnaireViewModelImpl(sessionManager: self.sessionManager, questionnaireType: .pre)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        XCTAssertTrue(self.sessionManager.queues.contains(where: { $0.queueID == "7s1gafig00ofg" }))
                        XCTAssertTrue(self.sessionManager.queues.contains(where: { $0.queueID == "76nr0l4m00t5" }))
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
