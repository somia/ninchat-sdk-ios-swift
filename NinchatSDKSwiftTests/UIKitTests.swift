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
        
        waitForExpectations(timeout: 5.0)
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
    
    func test_expandableUITextView() {
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 0))
        XCTAssertEqual(textView.bounds.height, 0)
        
        textView.insertText("first line")
        textView.insertText("\n")
        textView.insertText("second line")
        
        textView.fix(height: 10)
        textView.updateSize(to: textView.newSize())
        XCTAssertGreaterThan(textView.newSize(), 0)
    }
    
    func test_inputController() {
        let view: ChatInputControls = ChatInputControls.loadFromNib()
        
        let expect_text = self.expectation(description: "Expected to get inserted text")
        view.onSendTapped = { text in
            XCTAssertEqual(text, "send text\n\nEOT")
            expect_text.fulfill()
        }
    
        let expect_attachment = self.expectation(description: "Expected to trigger attachment event")
        view.onAttachmentTapped = { button in
            XCTAssertNotNil(button)
            expect_attachment.fulfill()
        }
    
        var expectedWritingStatus = true
        view.onWritingStatusChanged = { status in
            XCTAssertEqual(status, expectedWritingStatus)
        }
        
        var expected_size: CGFloat = 33.0
        view.onTextSizeChanged = { newSize in
            XCTAssertGreaterThanOrEqual(newSize, expected_size)
            expected_size = newSize
        }
    
        expectedWritingStatus = true
        view.textInput.insertText("send text")
        view.textInput.insertText("\n\n")
        view.textInput.insertText("EOT")
    
        expectedWritingStatus = false
        expected_size = 33.0
        view.onSendButtonTapped(sender: view.sendMessageButton)
        view.onAttachmentButtonTapped(sender: view.attachmentButton)
        XCTAssertFalse(view.isSelected)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func test_button() {
        let expect_button = self.expectation(description: "The `UIButton` action is fulfilled")
        let button = Button(frame: .zero, touch: { button in
            XCTAssertNotNil(button as? Button)
            expect_button.fulfill()
        })
        button.sendActions(for: .touchUpInside)
        
        let expect_close = self.expectation(description: "The `CloseButton` action is fulfilled")
        let close = CloseButton(frame: .zero)
        close.closure = { button in
            expect_close.fulfill()
        }
        close.theButton.sendActions(for: .touchUpInside)
        
        waitForExpectations(timeout: 0.2, handler: nil)
    }
    
    func test_videoView() {
        let videoView: VideoView = VideoView.loadFromNib()
        
        let expectationHangup = self.expectation(description: "Expect to get hangup action")
        videoView.onHangupTapped = { button in
            XCTAssertNotNil(button)
            expectationHangup.fulfill()
        }
        videoView.hangupAction()
        
        let expectationMute = self.expectation(description: "Expect to get mute action")
        videoView.onAudioTapped = { button in
            XCTAssertNotNil(button)
            expectationMute.fulfill()
        }
        videoView.audioAction()
        
        let expectationCamera = self.expectation(description: "Expect to get camera disable action")
        videoView.onCameraTapped = { button in
            XCTAssertNotNil(button)
            expectationCamera.fulfill()
        }
        videoView.cameraAction()
        
        XCTAssertFalse(videoView.isSelected)
        videoView.isSelected = true
        XCTAssertTrue(videoView.microphoneEnabledButton.isSelected)
        XCTAssertTrue(videoView.cameraEnabledButton.isSelected)
        
        wait(for: [expectationHangup, expectationMute, expectationCamera], timeout: 1.0)
    }
    
    func test_subviews() {
        let parent1 = UIView(frame: .zero)
        parent1.tag = 1
        
        let child1 = UIView(frame: .zero)
        child1.tag = 11
        
        let child2 = UIView(frame: .zero)
        child1.tag = 12
        
        let grandChild1 = UIView(frame: .zero)
        grandChild1.tag = 111
        
        child1.addSubview(grandChild1)
        parent1.addSubview(child1)
        parent1.addSubview(child2)
        
        XCTAssertEqual(3, parent1.allSubviews.count)
    }
    
    func test_font() {
        XCTAssertNotNil(UIFont.ninchat)
    }
}

extension UIKitTests {
    private func simulateSendMessage() {
        let user = NINChannelUser(id: "11", realName: "Hassan Shahbazi", displayName: "Hassan", iconURL: "", guest: false)
        let textMessage = NINTextMessage(messageID: "00", textContent: "content", sender: user!, timestamp: Date(), mine: false, attachment: nil)
        self.sessionManager.add(message: textMessage)
    }
}