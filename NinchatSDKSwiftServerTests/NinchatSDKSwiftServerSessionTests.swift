//
// Copyright (c) 14.4.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

final class NinchatSDKSwiftServerSessionTests: XCTestCase {
    private var sessionManager: NINChatSessionManagerImpl!

    override func setUp() {
        super.setUp()

        self.sessionManager = Session.initiate()
    }

    override func tearDown() {
        super.tearDown()

        self.closeSession { _ in
            self.sessionManager.deallocateSession()
        }
    }

    func testServer_closeOldSession() {
        let expect_close_session = self.expectation(description: "Expected to close the session with status code success")
        let expect_leave = self.expectation(description: "Expected to close the session after the test is finished")
        expect_leave.assertForOverFulfill = false

        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { _ in
            XCTAssertEqual(self.sessionManager.siteConfiguration.userName, "Asiakas (öäå)")

            self.openSession { credentials1 in
                /// A useless session, to be closed once the other is opened.
                XCTAssertNotNil(credentials1)

                self.openSession { credentials2 in
                    /// The main session. Has to close the other one simultaneously
                    XCTAssertNotNil(credentials2)

                    /// Should now close the useless one
                    self.sessionManager.closeSession(credentials: credentials1!) { result in
                        switch result {
                        case .success:
                            expect_close_session.fulfill()
                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }
                        self.closeSession { error in
                            XCTAssertNil(error)
                            self.sessionManager.deallocateSession()
                            expect_leave.fulfill()
                        }
                    }
                }
            }
        }

        /// The test needs a manual interaction from server to fulfills all expectations
        waitForExpectations(timeout: 10.0)
    }

    func testServer_joinClosedSession() {
        guard let closedQueue = Session.closedQueue else {
            XCTAssertTrue(true, "Skipping the test. No associated key for 'queue-closed' in configuration file found."); return
        }
        let expect = self.expectation(description: "Expected to not join the queue")
        expect.assertForOverFulfill = false

        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { _ in
            try? self.sessionManager.openSession { _, _, error in
                XCTAssertNil(error)

                try? self.sessionManager.list(queues: self.sessionManager.siteConfiguration.audienceQueues) { error in
                    XCTAssertNil(error)

                    XCTAssertTrue(self.sessionManager.audienceQueues.first(where: { $0.queueID == closedQueue })?.isClosed ?? false)
                    try! self.sessionManager.join(queue: closedQueue, progress: { queue, error, position in
                        XCTFail("The join cannot be completed")
                    }, completion: {
                        XCTFail("The join cannot be completed")
                    })

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        expect.fulfill()
                    }
                }
            }
        }

        /// The test needs a manual interaction from server to fulfills all expectations
        waitForExpectations(timeout: 10.0)
    }

    func testServer_dynamicUserName() {
        let expect = self.expectation(description: "Expected to override configurations")

        self.sessionManager = Session.initiate(NINSiteConfigurationImpl(userName: "Hassan - iPhone"))
        XCTAssertNotNil(self.sessionManager.givenConfiguration?.userName)
        XCTAssertEqual(self.sessionManager.givenConfiguration?.userName, "Hassan - iPhone")

        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { error in
            do {
                try self.sessionManager.openSession { _, _, error in
                    XCTAssertNil(error)

                    XCTAssertNotNil(self.sessionManager.siteConfiguration.userName)
                    XCTAssertEqual(self.sessionManager.siteConfiguration.userName, "Hassan - iPhone")
                    expect.fulfill()
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testServer_configuration() {
        let expect = self.expectation(description: "Expected to get pre-questionnaire configurations")
        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: ["default"]) { error in 
            XCTAssertNil(error)
            XCTAssertNotNil(self.sessionManager.siteConfiguration)
            XCTAssertNotNil(self.sessionManager.siteConfiguration.preAudienceQuestionnaire)
            XCTAssertGreaterThan(self.sessionManager.siteConfiguration.preAudienceQuestionnaire?.count ?? 0, 0)
            expect.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }
}

extension NinchatSDKSwiftServerSessionTests: QueueUpdateCapture {
    var desc: String {
        "NinchatSDKSwiftServerSessionTests"
    }
}

extension NinchatSDKSwiftServerSessionTests {
    private func openSession(queue: String = Session.suiteQueue, completion: @escaping (NINSessionCredentials?) -> Void) {
        do {
            try self.sessionManager.openSession { credentials, _, _ in
                try! self.sessionManager.list(queues: self.sessionManager.siteConfiguration.audienceQueues) { _ in
                    try! self.sessionManager.join(queue: queue, progress: { queue, error, position in }, completion: {
                        completion(credentials)
                    })
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    private func closeSession(completion: @escaping (Error?) -> Void) {
        do {
            try self.sessionManager.deleteCurrentUser { error in
                self.sessionManager.disconnect()
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    internal func simulateTextMessage(_ message: String) throws {
        try self.sessionManager.send(message: message, completion: { _ in })
    }
}
