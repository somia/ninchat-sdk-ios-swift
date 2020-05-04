//
// Copyright (c) 25.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import WebRTC

protocol NINWebRTCActions {
    var onActionError: ((Error) -> Void)? { get set }
    var onRemoteVideoTrack: ((RTCVideoRenderer, RTCVideoTrack) -> Void)? { get set }
    var onLocalCapture: ((RTCCameraVideoCapturer) -> Void)? { get set }
}

protocol NINWebRTCDelegate: NINChatWebRTCClientDelegate, NINWebRTCActions {
    init(remoteVideoDelegate: RTCVideoViewDelegate)
}

final class NINWebRTCDelegateImpl: NINWebRTCDelegate {
    
    // MARK: - NINChatWebRTCClientDelegate
    
    var onConnectionStateChange: ((NINChatWebRTCClient, ConnectionState) -> Void)?
    var onLocalCaptureCreate: ((NINChatWebRTCClient, RTCCameraVideoCapturer) -> Void)?
    var onRemoteVideoTrackReceive: ((NINChatWebRTCClient, RTCVideoTrack) -> Void)?
    var onError: ((NINChatWebRTCClient, Error) -> Void)?
    
    // MARK: - NINWebRTCActions
    
    var onActionError: ((Error) -> Void)?
    var onRemoteVideoTrack: ((RTCVideoRenderer, RTCVideoTrack) -> Void)?
    var onLocalCapture: ((RTCCameraVideoCapturer) -> Void)?
    
    // MARK: - NINWebRTCDelegate
    
    private let remoteVideoDelegate: RTCVideoViewDelegate
    
    init(remoteVideoDelegate: RTCVideoViewDelegate) {
        self.remoteVideoDelegate = remoteVideoDelegate
        
        self.onConnectionStateChange = { client, newState in
            debugger("WebRTC new state: \(newState.description)")
        }
        
        self.onLocalCaptureCreate = { [weak self] client, capturer in
            debugger("didCreateLocalCapturer: \(String(describing: capturer))")
            self?.onLocalCapture?(capturer)
        }
        
        /** Called when the video call is initiated and the remote video track is available. */
        self.onRemoteVideoTrackReceive = { [weak self] client, remoteVideoTrack in
            debugger("NINCHAT: didReceiveRemoteVideoTrack: \(String(describing: remoteVideoTrack))")
            
            #if RTC_SUPPORTS_METAL
            let remoteView = RTCMTLVideoView(frame: .zero)
            remoteVide.delegate = remoteVideoDelegate
            self.onRemoteVideoTrack?(remoteView, remoteVideoTrack)
            #else
            let remoteView = RTCEAGLVideoView(frame: .zero)
            remoteView.delegate = remoteVideoDelegate
            self?.onRemoteVideoTrack?(remoteView, remoteVideoTrack)
            #endif
        }
        
        self.onError = { [weak self] client, error in
            debugger("NINCHAT: didGetError: \(String(describing: error))")
            self?.onActionError?(error)
        }
    }
}
