//
// Copyright (c) 19.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import XCTest
@testable import NinchatSDKSwift

final class UIKitTests: XCTestCase {
    var sessionSwift: NINChatSession!
    var sessionManager: NINChatSessionManagerImpl!
    private let superview = UIView(frame: .zero)
    
    override func setUp() {
        sessionSwift = NINChatSession(configKey: "")
        sessionManager = NINChatSessionManagerImpl(session: InternalDelegate(session: sessionSwift), serverAddress: "", configuration: nil)
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
        
        waitForExpectations(timeout: 30.0)
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

    func test_choiceDialogue_option() {
        let view: ChoiceDialogue = ChoiceDialogue.loadFromNib()
        
        let expect_option = self.expectation(description: "Expected to get option get selected")
        view.showDialogue(withOptions: ["1", "2"]) { result in
            switch result {
            case .select(let index):
                XCTAssertEqual(index, 1)
            case .cancel:
                XCTAssertTrue(false, "Cancel options shouldn't have been tapped")
            }
    
            expect_option.fulfill()
        }
        XCTAssertEqual(view.stackView.subviews.count, 3)
        (view.stackView.subviews[1] as? ChoiceDialogueRow)?.onRowButtonTapped(nil)
        
        waitForExpectations(timeout: 5.0)
    }
    
    func test_choiceDialogue_cancel() {
        let view: ChoiceDialogue = ChoiceDialogue.loadFromNib()
    
        let expect_cancel = self.expectation(description: "Expected to get canceled")
        view.showDialogue(withOptions: ["1", "2"], cancelTitle: "Cancel") { result in
            switch result {
            case .select:
                XCTAssertTrue(false, "Select options shouldn't have been tapped")
            case .cancel:
                XCTAssertTrue(true)
            }
        
            expect_cancel.fulfill()
        }
        XCTAssertEqual(view.stackView.subviews.count, 3)
        (view.stackView.subviews.last as? ChoiceDialogueRow)?.onRowButtonTapped(nil)
    
        waitForExpectations(timeout: 5.0)
    }

    func test_toast() {
        let view: Toast = Toast.loadFromNib()

        let expect_touch = self.expectation(description: "Expected to get the toast touched")
        let expect_dismiss = self.expectation(description: "Expected to get the toast dismissed")
        view.show(message: .info("This is a toast"), onToastTouched: {
            expect_touch.fulfill()
        }, onToastDismissed: {
            expect_dismiss.fulfill()
        })
        XCTAssertEqual(view.messageLabel.text, "This is a toast")
        XCTAssertEqual(view.containerView.backgroundColor, UIColor.toastInfoBackground)

        view.onViewTapped(nil)
        waitForExpectations(timeout: 5.0)
    }

    func test_toast_dismiss() {

    }
}

extension UIKitTests {
    private func simulateSendMessage() {
        let user = ChannelUser(userID: "11", realName: "Hassan Shahbazi", displayName: "Hassan", iconURL: "", guest: false)
        self.sessionManager.add(message: TextMessage(timestamp: Date(), messageID:  "11", mine: false, sender: user, textContent: "content", attachment: nil))
    }
}
