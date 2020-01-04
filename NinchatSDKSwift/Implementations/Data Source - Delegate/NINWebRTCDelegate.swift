//
// Copyright (c) 25.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

protocol NINWebRTCActions {
    var onError: ((Error) -> Void)? { get set }
    var onRemoteVideoTrack: ((RTCVideoRenderer, RTCVideoTrack) -> Void)? { get set }
    var onLocalCapturer: ((RTCCameraVideoCapturer) -> Void)? { get set }
}

protocol NINWebRTCDelegate: NINWebRTCClientDelegate, NINWebRTCActions {
    init(remoteVideoDelegate: RTCVideoViewDelegate)
}

final class NINWebRTCDelegateImpl: NSObject, NINWebRTCDelegate {
    
    // MARK: - NINWebRTCActions
    
    var onError: ((Error) -> Void)?
    var onRemoteVideoTrack: ((RTCVideoRenderer, RTCVideoTrack) -> Void)?
    var onLocalCapturer: ((RTCCameraVideoCapturer) -> Void)?
    
    // MARK: - NINWebRTCDelegate
    
    private let remoteVideoDelegate: RTCVideoViewDelegate
    
    init(remoteVideoDelegate: RTCVideoViewDelegate) {
        self.remoteVideoDelegate = remoteVideoDelegate
    }
}

// MARK: - NINWebRTCClientDelegate

extension NINWebRTCDelegateImpl {
    func webrtcClient(_ client: NINWebRTCClient!, didGetError error: Error!) {
        debugger("NINCHAT: didGetError: \(String(describing: error))")
        self.onError?(error)
    }
    
    func webrtcClient(_ client: NINWebRTCClient!, didChange newState: RTCIceConnectionState) {
        debugger("WebRTC new state: \(newState.rawValue)")
    }
    
    /** Called when the video call is initiated and the remote video track is available. */
    func webrtcClient(_ client: NINWebRTCClient!, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack!) {
        debugger("NINCHAT: didReceiveRemoteVideoTrack: \(String(describing: remoteVideoTrack))")
        
        #if RTC_SUPPORTS_METAL
        let remoteView = RTCMTLVideoView(frame: .zero)
        remoteVide.delegate = remoteVideoDelegate
        
        self.onRemoteVideoTrack?(remoteView, remoteVideoTrack)
        #else
        let remoteView = RTCEAGLVideoView(frame: .zero)
        remoteView.delegate = remoteVideoDelegate
        
        self.onRemoteVideoTrack?(remoteView, remoteVideoTrack)
        #endif
    }
    
    func webrtcClient(_ client: NINWebRTCClient!, didCreateLocalCapturer localCapturer: RTCCameraVideoCapturer!) {
        debugger("didCreateLocalCapturer: \(String(describing: localCapturer))")
        self.onLocalCapturer?(localCapturer)
    }
}
