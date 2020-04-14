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
        let expect_error_resume = self.expectation(description: "Expected to get error if trying to resume a deallocated session")

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
                        expect_error_resume.fulfill()
                    }

                }
            }
        }

        waitForExpectations(timeout: 20.0)
    }
}

extension NinchatSDKSwiftServerSessionTests {
    private func openSession(completion: @escaping ((NINSessionCredentials?) -> Void)) {
        do {
            try self.sessionManager.openSession { credentials, _, _ in
                try! self.sessionManager.list(queues: self.sessionManager.siteConfiguration.audienceQueues) { _ in
                    try! self.sessionManager.join(queue: Session.suiteQueue, progress: { queue, error, position in }, completion: {
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
}