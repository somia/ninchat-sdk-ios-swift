//
// Copyright (c) 14.4.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatLowLevelClient
@testable import NinchatSDKSwift

final class NinchatSDKSwiftServerSessionTests: XCTestCase {
    private var sessionManager = Session.Manager

    func testServer_closeOldSession() {
        let expect_close_session = self.expectation(description: "Expected to close the session with status code success")
        let expect_leave = self.expectation(description: "Expected to close the session after the test is finished")

        self.sessionManager.fetchSiteConfiguration(config: Session.configurationKey, environments: []) { _ in
            self.openSession { credentials1 in
                XCTAssertNotNil(credentials1)

                /// Open another session while the other one is still open
                self.resumeSession(credentials: credentials1!) { credentials2, error in
                    XCTAssertNil(error)
                    XCTAssertNotNil(credentials2)
                    XCTAssertNotEqual(credentials2?.sessionID, credentials1?.sessionID)

                    self.sessionManager.closeSession(credentials: credentials1!) { result in
                        switch result {
                        case .success:
                            XCTAssertTrue(true)
                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }
                        expect_close_session.fulfill()

                        self.sessionManager.leave { error in
                            XCTAssertNil(error)
                            self.closeSession { error in
                                XCTAssertNil(error)
                                expect_leave.fulfill()
                            }
                        }
                    }
                }
            }
        }

        /// The test needs a manual interaction from server to fulfills all expectations
        waitForExpectations(timeout: 20.0)
    }

    func testServer_joinClosedSession() {
        guard let closedQueue = Session.closedQueue else {
            XCTAssertTrue(true, "Skipping the test. No associated key for 'queue-closed' in configuration file found."); return
        }
        let expect = self.expectation(description: "Expected to not join the queue")
        expect.assertForOverFulfill = false

        sleep(10)
        self.sessionManager.audienceQueues = []
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

                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                        expect.fulfill()
                    }
                }
            }
        }

        /// The test needs a manual interaction from server to fulfills all expectations
        waitForExpectations(timeout: 20.0)
    }
}

extension NinchatSDKSwiftServerSessionTests: QueueUpdateCapture {
    var desc: String {
        "NinchatSDKSwiftServerSessionTests"
    }
}

extension NinchatSDKSwiftServerSessionTests {
    private func openSession(queue: String = Session.suiteQueue, completion: @escaping ((NINSessionCredentials?) -> Void)) {
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

    private func resumeSession(credentials: NINSessionCredentials, completion: @escaping ((NINSessionCredentials?, Error?) -> Void)) {
        do {
            try self.sessionManager.continueSession(credentials: credentials) { credentials, _, error in
                completion(credentials, error)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    private func closeSession(completion: @escaping ((Error?) -> Void)) {
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