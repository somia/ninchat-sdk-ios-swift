//
//  NINChatViewModelTests.swift
//  NinchatSDKSwiftTests
//
//  Created by Hassan Shahbazi on 22.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

class NINChatViewModelTests: XCTestCase {
    var viewModel: NINChatViewModel!
    
    override func setUp() {
        let session = NINChatSessionSwift(configKey: "")
        viewModel = NINChatViewModelImpl(session: session)
    }

    override func tearDown() { }
    
    func testProtocolConformance() {
        XCTAssertNotNil(viewModel)
        XCTAssertNotNil(viewModel as NINChatMessageProtocol)
        XCTAssertNotNil(viewModel as NINChatStateProtocol)
        XCTAssertNotNil(viewModel as NINChatRTCProtocol)
    }
    
    func testRTCSignaling() {
        let expectationCall = self.expectation(description: "Expect to get a fake call")
        let expectationHangup = self.expectation(description: "Expect to get a hangup command")
        viewModel.listenToRTCSignaling(delegate: self, onCallReceived: { user in
            XCTAssertNil(user)
            expectationCall.fulfill()
        }, onCallInitiated: { error, rtc  in }, onCallHangup: {
            expectationHangup.fulfill()
        })
        XCTAssertNotNil(viewModel.signalingObserver)
        
        simulateSignalCall()
        simulateCallInitiate()
        simulateHangup()
        wait(for: [expectationCall, expectationHangup], timeout: 5.0)
    }
    
    func testRTCDisconnect() {
        let expectation = self.expectation(description: "The disconnect should happen")
        self.viewModel.disconnectRTC(NINWebRTCClient()) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMessageObservers() {
        let expectationCloseChat = self.expectation(description: "Expect to close the chat")
        viewModel.onChannelClosed = {
            expectationCloseChat.fulfill()
        }
        
        let expectationQueueChat = self.expectation(description: "Expect to back to the queue view controller")
        viewModel.onQueued = {
            expectationQueueChat.fulfill()
        }
        
        let expectationMessageInsert = self.expectation(description: "Expect to receive Message `insert` command")
        let expectationMessageRemove = self.expectation(description: "Expect to receive Message `remove` command")
        viewModel.onChannelMessage = { type in
            if case let .insert(index) = type {
                XCTAssertEqual(index, 0)
                expectationMessageInsert.fulfill()
            } else if case let .remove(index) = type {
                XCTAssertEqual(index, 1)
                expectationMessageRemove.fulfill()
            }
        }
        XCTAssertNotNil(viewModel.messageObserver)
        
        simulateChatClose()
        simulateChatQueue()
        simulateChatInsertMessage()
        simulateChatRemoveMessage()
        wait(for: [expectationCloseChat, expectationQueueChat, expectationMessageInsert, expectationMessageRemove], timeout: 1.0)
    }
}

// MARK: - RTC Signaling

extension NINChatViewModelTests {
    private func simulateSignalCall() {
        postNotification(NotificationConstants.kNINWebRTCSignalNotification.rawValue,
                         ["messageType": WebRTCConstants.kNINMessageTypeWebRTCOffer.rawValue])
    }
    
    private func simulateCallInitiate() {
        postNotification(NotificationConstants.kNINWebRTCSignalNotification.rawValue,
                         ["messageType": WebRTCConstants.kNINMessageTypeWebRTCCall.rawValue,
                          "payload": ["sdp":""]])
    }
    
    private func simulateHangup() {
        postNotification(NotificationConstants.kNINWebRTCSignalNotification.rawValue,
                         ["messageType": WebRTCConstants.kNINMessageTypeWebRTCHangup.rawValue])
    }
}

// MARK: - Message Observers

extension NINChatViewModelTests {
    private func simulateChatClose() {
        postNotification(NotificationConstants.kNINChannelClosedNotification.rawValue, [:])
    }
    
    private func simulateChatQueue() {
        postNotification(NotificationConstants.kNINQueuedNotification.rawValue,
                         ["event":"audience_enqueued"])
    }
    
    private func simulateChatInsertMessage() {
        postNotification(NotificationConstants.kChannelMessageNotification.rawValue,
                         ["index": 0,
                          "action": "insert"])
    }
    
    private func simulateChatRemoveMessage() {
        postNotification(NotificationConstants.kChannelMessageNotification.rawValue,
                         ["index": 1,
                          "action": "remove"])
    }
}

extension NINChatViewModelTests: NINWebRTCClientDelegate {
    func webrtcClient(_ client: NINWebRTCClient!, didChange newState: RTCIceConnectionState) {}
    
    func webrtcClient(_ client: NINWebRTCClient!, didCreateLocalCapturer localCapturer: RTCCameraVideoCapturer!) {}
    
    func webrtcClient(_ client: NINWebRTCClient!, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack!) {}
    
    func webrtcClient(_ client: NINWebRTCClient!, didGetError error: Error!) {}
}
