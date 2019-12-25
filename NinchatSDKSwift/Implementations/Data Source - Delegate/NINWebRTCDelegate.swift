//
//  NINWebRTCDelegate.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 25.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
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
        #if DEBUG
        print("NINCHAT: didGetError: \(String(describing: error))")
        #endif
        
        self.onError?(error)
    }
    
    func webrtcClient(_ client: NINWebRTCClient!, didChange newState: RTCIceConnectionState) {
        #if DEBUG
        print("WebRTC new state: \(newState.rawValue)")
        #endif
    }
    
    /** Called when the video call is initiated and the remote video track is available. */
    func webrtcClient(_ client: NINWebRTCClient!, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack!) {
        #if DEBUG
        print("NINCHAT: didReceiveRemoteVideoTrack: \(String(describing: remoteVideoTrack))")
        #endif
        
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
        #if DEBUG
        print("didCreateLocalCapturer: \(String(describing: localCapturer))")
        #endif
        
        self.onLocalCapturer?(localCapturer)
    }
}
