//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

class UIMigrationTests: XCTestCase {
    override func setUp() { }

    override func tearDown() { }

    func testUIButtonAction() {
        let expectation = self.expectation(description: "The `UIButton` action is fulfilled")
        let button = Button(frame: .zero, touch: { button in
            XCTAssertNotNil(button as? Button)
            expectation.fulfill()
        })
        button.sendActions(for: .touchUpInside)
        
        waitForExpectations(timeout: 0.2, handler: nil)
    }
    
    func testExpandableUITextView() {
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 0))
        XCTAssertEqual(textView.bounds.height, 0)
        
        textView.insertText("first line")
        textView.insertText("\n")
        textView.insertText("second line")
        
        textView.fix(height: 10)
        textView.updateSize(to: textView.newSize())
        XCTAssertGreaterThan(textView.newSize(), 0)
    }
    
    func testTextInputView() {
        let inputView: ChatInputControls = ChatInputControls.loadFromNib()
        inputView.textInput.insertText("Test")
        
        let expectationSend = self.expectation(description: "Expect to get inserted text")
        inputView.onSendTapped = { text in
            XCTAssertEqual(text, "Test")
            expectationSend.fulfill()
        }
        inputView.sendAction()
        
        let expectationAttachment = self.expectation(description: "Expect to show attachment options")
        inputView.onAttachmentTapped = { button in
            XCTAssertNotNil(button)
            expectationAttachment.fulfill()
        }
        inputView.attachmentAction()
        
        XCTAssertFalse(inputView.isSelected)
        wait(for: [expectationSend, expectationAttachment], timeout: 1.0)
    }
    
    func testVideoView() {
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
    
    func testSubviews() {
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
}
