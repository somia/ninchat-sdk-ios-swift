//
// Copyright (c) 22.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import NinchatSDK
@testable import NinchatSDKSwift

class NINChatViewModelTests: XCTestCase {
    var sessionManager: NINChatSessionManager!
    var viewModel: NINChatViewModel!
    
    override func setUp() {
        let delegate = NINChatSessionSwift(configKey: "")
        sessionManager = NINChatSessionManagerImpl(session: delegate, serverAddress: "")
        viewModel = NINChatViewModelImpl(sessionManager: sessionManager)
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
    
    func testMessageClosures() {
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
        sessionManager.onRTCSignal?(.offer, nil, nil)
    }
    
    private func simulateCallInitiate() {
        sessionManager.onRTCSignal?(.call, nil, RTCSignal(candidate: [:], sdp: ["sdp": ""]))
    }
    
    private func simulateHangup() {
        sessionManager.onRTCSignal?(.hangup, nil, nil)
    }
}

// MARK: - Message Observers

extension NINChatViewModelTests {
    private func simulateChatClose() {
        sessionManager.onChannelClosed?()
    }
    
    private func simulateChatQueue() {
        sessionManager.onQueueUpdated?(.audienceEnqueued, "queue", nil, nil)
    }
    
    private func simulateChatInsertMessage() {
        sessionManager.onMessageAdded?(0)
    }
    
    private func simulateChatRemoveMessage() {
        sessionManager.onMessageRemoved?(1)
    }
}

extension NINChatViewModelTests: NINWebRTCClientDelegate {
    func webrtcClient(_ client: NINWebRTCClient!, didChange newState: RTCIceConnectionState) {}
    
    func webrtcClient(_ client: NINWebRTCClient!, didCreateLocalCapturer localCapturer: RTCCameraVideoCapturer!) {}
    
    func webrtcClient(_ client: NINWebRTCClient!, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack!) {}
    
    func webrtcClient(_ client: NINWebRTCClient!, didGetError error: Error!) {}
}
