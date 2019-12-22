//
//  VideoView.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 9.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit
import WebRTC

protocol VideoViewActions {
    typealias Action = ((UIButton) -> Void)
    var onHangupTapped: Action? { get set }
    var onAudioTapped: Action? { get set }
    var onCameraTapped: Action? { get set }
}

protocol VideoViewProtocol: UIView, VideoViewActions {
    var session: NINChatSessionSwift! { get set }
    var viewModel: NINChatViewModel! { get set }
    var localCapture: RTCCameraVideoCapturer? { get set }
    var remoteCapture: RTCVideoRenderer? { get set }
    var remoteVideoTrack: RTCVideoTrack? { get set }
    var isSelected: Bool! { get set }
    
    func overrideAssets()
    func resizeRemoteVideo(to size: CGSize)
    func resizeRemoteVideo()
    func resizeLocalVideo()
    
}

final class VideoView: UIView, VideoViewProtocol {
    private var currentVideoSize: CGSize?
    
    // MARK: - VideoViewProtocol
    
    var session: NINChatSessionSwift!
    var viewModel: NINChatViewModel!
    var onHangupTapped: Action?
    var onAudioTapped: Action?
    var onCameraTapped: Action?
    var localCapture: RTCCameraVideoCapturer? {
        didSet {
            localVideoView.captureSession = localCapture?.captureSession
        }
    }
    var remoteCapture: RTCVideoRenderer? {
        willSet {
            if let view = self.remoteCapture as? UIView {
                view.removeFromSuperview()
            }
        }
        didSet {
            guard let view = remoteCapture as? UIView else {
                fatalError("Unable to convert `RTCVideoRenderer` to `UIView`")
            }
            
            self.remoteVideoViewContainer.addSubview(view)
            view
                .fix(left: (0.0, remoteVideoViewContainer), right: (0.0, remoteVideoViewContainer), isRelative: false)
                .fix(top: (0.0, remoteVideoViewContainer), bottom: (0.0, remoteVideoViewContainer), isRelative: false)
        }
    }
    var remoteVideoTrack: RTCVideoTrack? {
        willSet {
            if let capture = remoteCapture {
                remoteVideoTrack?.remove(capture)
                capture.renderFrame(nil)
            }
        }
        didSet {
            if let capture = remoteCapture {
                self.remoteVideoTrack?.add(capture)
            }
        }
    }
    var isSelected: Bool! = false {
        didSet {
            microphoneEnabledButton.isSelected = isSelected
            cameraEnabledButton.isSelected = isSelected
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var videoContainerView: UIView!
    
    @IBOutlet private(set) weak var remoteVideoViewContainer: UIView!
    @IBOutlet private(set) weak var remoteViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private(set) weak var remoteViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet private(set) weak var localVideoView: RTCCameraPreviewView!
    @IBOutlet private(set) weak var localViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private(set) weak var localViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet private(set) weak var hangupButton: UIButton! {
        didSet {
            hangupButton.roundCorners()
        }
    }
    @IBOutlet private(set) weak var microphoneEnabledButton: UIButton! {
        didSet {
            microphoneEnabledButton.roundCorners()
        }
    }
    @IBOutlet private(set) weak var cameraEnabledButton: UIButton! {
        didSet {
            cameraEnabledButton.roundCorners()
        }
    }
    
    func overrideAssets() {
        if let hangupIcon = self.session.override(imageAsset: .iconVideoHangup) {
            self.hangupButton.setImage(hangupIcon, for: .normal)
        }
        
        if let micOnIcon = self.session.override(imageAsset: .iconVideoMicrophoneOn) {
            self.microphoneEnabledButton.setImage(micOnIcon, for: .normal)
        }
        
        if let micOffIcon = self.session.override(imageAsset: .iconVideoMicrophoneOff) {
            self.microphoneEnabledButton.setImage(micOffIcon, for: .selected)
        }
        
        if let cameraOnIcon = self.session.override(imageAsset: .iconVideoCameraOn) {
            self.cameraEnabledButton.setImage(cameraOnIcon, for: .normal)
        }
        
        if let cameraOffIcon = self.session.override(imageAsset: .iconVideoCameraOff) {
            self.cameraEnabledButton.setImage(cameraOffIcon, for: .selected)
        }
    }
        
    func resizeRemoteVideo() {
        self.resizeRemoteVideo(to: self.currentVideoSize ?? .zero)
    }
    
    func resizeRemoteVideo(to size: CGSize) {
        #if DEGBU
        print("Adjusting remote video view size")
        #endif
        
        let aspectRatio = (size == .zero) ? CGSize(width: 4, height: 3) : size
        let videoFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: self.videoContainerView.bounds)
        self.remoteViewWidthConstraint.constant = videoFrame.width
        self.remoteViewHeightConstraint.constant = videoFrame.height
        
        self.currentVideoSize = size
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    func resizeLocalVideo() {
        let containerWidth = self.videoContainerView.bounds.width
        let containerHeight = self.videoContainerView.bounds.height
        guard containerWidth > 1, containerHeight > 1 else { return }
        
        #if DEBUG
        print("Adjusting local video view size")
        #endif
        
        let videoRect = CGRect(x: 0, y: 0, width: containerWidth / 3, height: containerHeight / 3)
        self.localViewWidthConstraint.constant = videoRect.width
        self.localViewHeightConstraint.constant = videoRect.height
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - User actions
    
    @IBAction private func onHangupButtonTapped(sender: UIButton) {
        self.onHangupTapped?(sender)
    }
    
    @IBAction private func onAudioButtonTapped(sender: UIButton) {
        self.onAudioTapped?(sender)
    }
    
    @IBAction private func onCameraButtonTapped(sender: UIButton) {
        self.localVideoView.isHidden = !cameraEnabledButton.isSelected
        self.onCameraTapped?(sender)
    }
}

// MARK: - Test Facilities

extension VideoView {
    internal func hangupAction() {
        self.onHangupButtonTapped(sender: hangupButton)
    }
    
    internal func audioAction() {
        self.onAudioButtonTapped(sender: microphoneEnabledButton)
    }
    
    internal func cameraAction() {
        self.onCameraButtonTapped(sender: cameraEnabledButton)
    }
}
