//
// Copyright (c) 19.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

final class UIKitTests: XCTestCase {
    var sessionSwift: NINChatSessionSwift!
    var sessionManager: NINChatSessionManagerImpl!
    private let superview = UIView(frame: .zero)
    
    override func setUp() {
        sessionSwift = NINChatSessionSwift(configKey: "")
        sessionManager = NINChatSessionManagerImpl(session: sessionSwift, serverAddress: "")
    }
    
    func test_confirmView() {
        let view = ConfirmCloseChatView.loadFromNib()
        XCTAssertNotNil(view as? ConfirmView)
        
        (view as? ConfirmView)?.showConfirmView(on: self.superview)
        XCTAssertEqual(view.transform, .identity)
        
        let expect_show = self.expectation(description: "Expected the view to be shown")
        let expect_hide = self.expectation(description: "Expected the view to be hidden")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.superview.subviews.count, 2) /// fadeView as the subview of superview
            XCTAssertEqual(self.superview.subviews.filter {
                $0 as? ConfirmView != nil
            }.count, 1)
            XCTAssertEqual(self.superview.subviews.filter {
                $0 as? FadeView != nil
            }.count, 1)
            
            expect_show.fulfill()
            
            (view as? ConfirmView)?.hideConfirmView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                XCTAssertEqual(self.superview.subviews.count, 0)
                XCTAssertEqual(self.superview.subviews.filter {
                    $0 as? ConfirmView != nil
                }.count, 0)
                XCTAssertEqual(self.superview.subviews.filter {
                    $0 as? FadeView != nil
                }.count, 0)
                
                expect_hide.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.2)
    }
    
    func test_faceView() {
        let view: FacesView = FacesView.loadFromNib()
        
        let expect_positive = self.expectation(description: "Expected the positive button to be tapped")
        view.onPositiveTapped = { button in
            XCTAssertNotNil(button)
            expect_positive.fulfill()
        }
        view.onPositiveButtonTapped(sender: view.positiveButton)
    
        let expect_neutral = self.expectation(description: "Expected the neutral button to be tapped")
        view.onNeutralTapped = { button in
            XCTAssertNotNil(button)
            expect_neutral.fulfill()
        }
        view.onNeutralButtonTapped(sender: view.neutralButton)
    
        let expect_negative = self.expectation(description: "Expected the negative button to be tapped")
        view.onNegativeTapped = { button in
            XCTAssertNotNil(button)
            expect_negative.fulfill()
        }
        view.onNegativeButtonTapped(sender: view.negativeButton)
        
        waitForExpectations(timeout: 1.0)
    }
}

extension UIKitTests {
    private func simulateSendMessage() {
        let user = NINChannelUser(id: "11", realName: "Hassan Shahbazi", displayName: "Hassan", iconURL: "", guest: false)
        let textMessage = NINTextMessage(messageID: "00", textContent: "content", sender: user!, timestamp: Date(), mine: false, attachment: nil)
        self.sessionManager.add(message: textMessage)
    }
}