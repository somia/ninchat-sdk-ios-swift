//
// Copyright (c) 20.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

enum OperatingMode {
    case caller
    case callee
    
    var description: String {
        switch self {
        case .caller: return "CALLER"
        case .callee: return "CALEE"
        }
    }
}

/** Represents the signaling state of the peer connection. */
enum SignalingState: Int, CaseIterable {
    case stable = 0
    case haveLocalOffer = 1
    case haveLocalPrAnswer = 2
    case haveRemoteOffer = 3
    case haveRemotePrAnswer = 4
    /// Not an actual state, represents the total number of states.
    case closed = 5
    
    var description: String {
        switch self {
        case .stable: return "RTCSignalingStateStable"
        case .haveLocalOffer: return "RTCSignalingStateHaveLocalOffer"
        case .haveLocalPrAnswer: return "RTCSignalingStateHaveLocalPrAnswer"
        case .haveRemoteOffer: return "RTCSignalingStateHaveRemoteOffer"
        case .haveRemotePrAnswer: return "RTCSignalingStateHaveRemotePrAnswer"
        case .closed: return "RTCSignalingStateClosed"
        }
    }
}

/** Represents the ice connection state of the peer connection. */
enum ConnectionState: Int, CaseIterable {
    case now = 0
    case checking = 1
    case connected = 2
    case completed = 3
    case failed = 4
    case disconnected = 5
    case closed = 6
    case count = 7
    
    var description: String {
        switch self {
        case .now: return "RTCIceConnectionStateNew"
        case .checking: return "RTCIceConnectionStateChecking"
        case .connected: return "RTCIceConnectionStateConnected"
        case .completed: return "RTCIceConnectionStateCompleted"
        case .failed: return "RTCIceConnectionStateFailed"
        case .disconnected: return "RTCIceConnectionStateDisconnected"
        case .closed: return "RTCIceConnectionStateClosed"
        case .count: return "RTCIceConnectionStateCount"
        }
    }
}

/** Represents the ice gathering state of the peer connection. */
enum GatheringState: Int, CaseIterable {
    case new = 0
    case gathering = 1
    case complete = 2
    
    var description: String {
        switch self {
        case .new: return "RTCIceGatheringStateNew"
        case .gathering: return "RTCIceGatheringStateGathering"
        case .complete: return "RTCIceGatheringStateComplete"
        }
    }
}

/**
* Delegate protocol for `NINChatWebRTCClient`.
*/
protocol NINChatWebRTCClientDelegate {
    /** Connection state was changed. */
    var onConnectionStateChange: ((NINChatWebRTCClient, ConnectionState) -> Void)? { get set }

    /** A local video capturer was created. */
    var onLocalCapturerCreate: ((NINChatWebRTCClient, RTCCameraVideoCapturer) -> Void)? { get set }

    /** A new remote video track was initiated. */
    var onRemoteVideoTrackReceive: ((NINChatWebRTCClient, RTCVideoTrack) -> Void)? { get set }

    /** An unrecoverable error occurred. */
    var onError: ((NINChatWebRTCClient, Error) -> Void)? { get set }
}

protocol NINChatWebRTCClient {
    var disableLocalAudio: Bool! { get set }
    var disableLocalVideo: Bool! { get set }
    
    init(sessionManager: NINChatSessionManager?, operatingMode: OperatingMode, stunServers: [WebRTCServerInfo]?, turnServers: [WebRTCServerInfo]?, delegate: NINChatWebRTCClientDelegate?)
    
    func start(with rtc: RTCSignal?) throws
    func disconnect()
}
