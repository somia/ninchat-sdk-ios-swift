//
// Copyright (c) 20.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import AVFoundation
import Foundation
import WebRTC

final class NINChatWebRTCClientImpl: NSObject, NINChatWebRTCClient {
    
    // MARK: - Constants
    private let kStreamId = "NINAMS"
    private let kAudioTrackId = "NINAMSa0"
    private let kVideoTrackId = "NINAMSv0"
    
    // MARK: - NINChatWebRTCClient
    
    private var delegate: NINChatWebRTCClientDelegate?
    /// Session manager, used for signaling
    private weak var sessionManager: NINChatSessionManager?
    /// Operation mode; caller or callee.
    private var operatingMode: OperatingMode!
    /// Factory for creating our RTC peer connections
    private var peerConnectionFactory: RTCPeerConnectionFactory?
    /// List of our ICE servers (STUN, TURN)
    private var iceServers: [RTCIceServer]? = []
    /// Mapping for the ICE signaling state --> state name
    private var iceSignalingStates: [Int:String] = [:]
    /// Mapping for the ICE connection state --> state name
    private var iceConnectionStates: [Int:String] = [:]
    /// Mapping for the ICE gathering state --> state name
    private var iceGatheringStates: [Int:String] = [:]
    
    /// Local video capture
    private var localCapture: RTCCameraVideoCapturer?
    /// Local media stream
    private var localStream: RTCMediaStream?
    /// Current RTC peer connection if any
    private var peerConnection: RTCPeerConnection?
    /// Local audio/video tracks
    private var localAudioTrack: RTCAudioTrack?
    private var localVideoTrack: RTCVideoTrack?
    /// RTP senders for local audio/video tracks
    private var localAudioSender: RTCRtpSender?
    private var localVideoSender: RTCRtpSender?

    private var sessionDelegate: NINChatSessionInternalDelegate? {
        self.sessionManager?.delegate
    }
    private var defaultOfferOrAnswerConstraints: RTCMediaConstraints {
        RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)
    }
    private var videoTransceiver: RTCRtpTransceiver? {
        self.peerConnection?.transceivers.filter({ $0.mediaType == .video }).first
    }
    
    var disableLocalAudio: Bool! {
        didSet {
            self.localAudioTrack?.isEnabled = !disableLocalAudio
        }
    }
    var disableLocalVideo: Bool! {
        didSet {
            #if !targetEnvironment(simulator)
            /// Camera capture only works on the device, not the simulator
            self.localVideoTrack?.isEnabled = !disableLocalVideo
            #endif
        }
    }
    
    init(sessionManager: NINChatSessionManager?, operatingMode: OperatingMode, stunServers: [WebRTCServerInfo]?, turnServers: [WebRTCServerInfo]?, candidates: [RTCIceCandidate]?, delegate: NINChatWebRTCClientDelegate?) {
        
        super.init()
        self.delegate = delegate
        self.sessionManager = sessionManager
        self.operatingMode = operatingMode
        self.peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(), decoderFactory: RTCDefaultVideoDecoderFactory())
        self.iceServers = [stunServers, turnServers].compactMap({ $0 }).reduce([], +).map({ $0.iceServer })
        
        self.iceSignalingStates = SignalingState.allCases.reduce(into: [:]) { (dic: inout [Int:String], item: SignalingState) in
            dic[item.rawValue] = item.description
        }
        self.iceConnectionStates = ConnectionState.allCases.reduce(into: [:]) { (dic: inout [Int:String], item: ConnectionState) in
            dic[item.rawValue] = item.description
        }
        self.iceGatheringStates = GatheringState.allCases.reduce(into: [:]) { (dic: inout [Int:String], item: GatheringState) in
            dic[item.rawValue] = item.description
        }
        
        /// Initiate peerConnection and add queued ICE Candidates
        self.initiatePeerConnection()
        for candidate in candidates ?? [] {
            debugger("WebRTC: Adding candidate: \(candidate) to peerConnection: \(String(describing: peerConnection))")
            self.peerConnection?.add(candidate)
        }
        
        sessionManager?.delegate?.log(value: "Creating new `NINChatWebRTCClient` in the '\(operatingMode.description)' mode")
        NotificationCenter.default.addObserver(self, selector: #selector(didSessionRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    func start(with rtc: RTCSignal?) throws {
        guard self.peerConnectionFactory != nil else { throw NINWebRTCExceptions.invalidState }
        guard self.sessionManager != nil else { throw NINSessionExceptions.noActiveSession }
        
        debugger("WebRTC: Starting..")
        sessionManager?.onRTCClientSignal = { [weak self] type, user, signal in
            switch type {
            case .candidate:
                debugger("WebRTC: Candidate received")
                guard let iceCandidate = signal?.candidate?.toRTCIceCandidate else { return }
                self?.peerConnection?.add(iceCandidate)
            case .answer:
                guard let sdp = signal?.sdp, sdp.values.count > 0, let description = sdp.toRTCSessionDescription else { return }
                debugger("WebRTC: Setting remote description from Answer with SDP: \(description)")
                self?.peerConnection?.setRemoteDescription(description) { error in
                    self?.didSetSessionDescription(with: error)
                }
            default:
                break
            }
        }
        
        /// Create a stream object; this is used to group the audio/video tracks together.
        self.localStream = self.peerConnectionFactory?.mediaStream(withStreamId: kStreamId)

        /// Set up the local audio & video sources / tracks
        self.createMediaSenders()
        
        switch operatingMode {
        case .caller:
            /// We are the 'caller', ie. the connection initiator; create a connection offer
            debugger("WebRTC: making a call.")
            self.peerConnection?.offer(for: self.defaultOfferOrAnswerConstraints) { [weak self] (sdp, error) in
                debugger("WebRTC: Created SDK offer with error: \(String(describing: error))")
                self?.didCreateSessionDescription(sdp: sdp, error: error)
            }
        case .callee:
            /// We are the 'callee', ie. we are answering.
            debugger("WebRTC: answering a call.")
            guard let description = rtc?.sdp?.toRTCSessionDescription else { return }
            debugger("WebRTC: Setting remote description from Offer.")
            self.peerConnection?.setRemoteDescription(description) { [weak self] error in
                self?.didSetSessionDescription(with: error)
            }
        default:
            fatalError("Invalid operation mode")
        }
    }
    
    func disconnect() {
        self.sessionDelegate?.log(value: "WebRTC: Client disconnecting.")
        
        self.stopLocalCapture()
        self.deallocate()
    }

    private func deallocate() {
        self.localStream = nil
        self.localCapture = nil

        if self.peerConnection != nil {
            if let stream = self.localStream {
                self.peerConnection?.remove(stream)
            }

            self.peerConnection?.close()
            self.peerConnection = nil
            self.peerConnectionFactory = nil
        }

        self.localAudioSender = nil
        self.localVideoSender = nil
        self.localAudioTrack = nil
        self.localVideoTrack = nil

        self.sessionManager?.onRTCClientSignal = nil
        self.sessionManager = nil

        self.iceSignalingStates.removeAll()
        self.iceConnectionStates.removeAll()
        self.iceGatheringStates.removeAll()
        self.iceServers?.removeAll()
        
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }

    deinit {
        debugger("`NINChatWebRTCClient` deallocated")
    }
}

extension NINChatWebRTCClientImpl {
    private func initiatePeerConnection() {
        /// Configure & create our RTC peer connection
        debugger("WebRTC: Configuring & initializing RTC Peer Connection")
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        let configuration = RTCConfiguration()
        configuration.iceServers = self.iceServers ?? []
        
        #if NIN_USE_PLANB_SEMANTICS
        debugger("WebRTC: Configuring peer connection for PlanB SDP semantics.")
        configuration.sdpSemantics = .planB /// <-- Legacy RTC impl support
        #else
        debugger("WebRTC: Configuring peer connection for Unified Plan SDP semantics.")
        configuration.sdpSemantics = .unifiedPlan
        #endif
        
        self.peerConnection = self.peerConnectionFactory?.peerConnection(with: configuration, constraints: constraints, delegate: self)
    }
    
    private func startLocalCapture() {
        DispatchQueue.main.async {
            let availableDevices = RTCCameraVideoCapturer.captureDevices()
            guard let device = availableDevices.filter({ $0.position == .front }).first ?? availableDevices.first else { return }
            
            /// We will try to find closest match for this video dimension
            let targetDimension = CGSize(width: 640, height: 480)
            var currentDiff = INT_MAX
            
            let availableFormats = RTCCameraVideoCapturer.supportedFormats(for: device)
            guard let format = availableFormats.map({ [weak self] format -> AVCaptureDevice.Format? in
                let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription)
                
                let diff = abs(Int32(targetDimension.width) - dimension.width) + abs(Int32(targetDimension.height) - dimension.height)
                
                if diff < currentDiff {
                    currentDiff = diff
                    return format
                }
                
                if diff == currentDiff && pixelFormat == self?.localCapture?.preferredOutputPixelFormat() {
                    return format
                }
                
                return nil
            }).filter({ $0 != nil }).last ?? availableFormats.first else {
                self.sessionDelegate?.log(value: "** ERROR No valid formats for device: \(device)"); return
            }
            
            debugger("WebRTC: Starting local video capturing..")
            let fps = fmin(format.videoSupportedFrameRateRanges
                                                        .map({ $0.maxFrameRate })
                                                        .sorted(by: { $0 > $1 })
                                                        .first ?? 0, 30)
            
            self.localCapture?.startCapture(with: device, format: format, fps: Int(fps)) { [weak self] (error: Error?) in
                if let error = error {
                    self?.sessionDelegate?.log(value: "** ERROR failed to start local capture: \(error)"); return
                }
                debugger("Local capture started OK.")
            }
        }
    }
    
    private func stopLocalCapture() {
        DispatchQueue.main.async {
            debugger("WebRTC: Stopping local video capturing..")
            self.localCapture?.stopCapture()
        }
    }
    
    private func didSetSessionDescription(with error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                debugger("WebRTC: got set session error: \(error)")
                self.disconnect()
                self.delegate?.onError?(self, error)
                return
            }
            
            guard self.operatingMode == .callee, self.peerConnection?.localDescription == nil else { return }
            debugger("WebRTC: Creating answer")
            self.peerConnection?.answer(for: self.defaultOfferOrAnswerConstraints) { [weak self] (sdp, error) in
                self?.didCreateSessionDescription(sdp: sdp, error: error)
            }
        }
    }
    
    private func didCreateSessionDescription(sdp: RTCSessionDescription?, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                debugger("WebRTC: got create session error: \(error)")
                self.disconnect()
                self.delegate?.onError?(self, error)
                return
            }
            
            guard let sdp = sdp, self.peerConnection?.localDescription?.type != sdp.type else { return }
            debugger("WebRTC: Setting local description")
            self.peerConnection?.setLocalDescription(sdp) { [weak self] error in
                self?.didSetSessionDescription(with: error)
            }
            
            /// Decide what type of signaling message to send based on the SDP type
            let typeMap: [RTCSdpType:MessageType] = [.offer:.offer, .answer:.answer]
            guard let messageType = typeMap[sdp.type] else {
                debugger("WebRTC: Unknown SDP type: \(sdp.type)"); return
            }
            
            /// Send signaling message about the offer/answer
            debugger("WebRTC: Sending RTC signaling message of type: \(messageType)")
            do {
                try self.sessionManager?.send(type: messageType, payload: ["sdp":sdp.toDictionary]) { error in
                    if let error = error {
                        debugger("WebRTC: Message send error - `completion`: \(error)")
                        Toast.show(message: .error("Failed to send RTC signaling message"))
                    }
                }
            } catch {
                debugger("WebRTC: Message send error - `sessionManager.send`: \(error)")
            }
        }
    }
}

// MARK: - Media stream

extension NINChatWebRTCClientImpl {
    private func createMediaSenders() {
        DispatchQueue.main.async {
            debugger("WebRTC: Configuring local audio & video sources")

            self.createVideoSender()
            self.createAudioSender()

            debugger("WebRTC: Local media senders configured.")
        }
    }

    /// Create local audio track and add it to the peer connection
    private func createAudioSender() {
        let constraint = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peerConnectionFactory?.audioSource(with: constraint)
        self.localAudioTrack = self.peerConnectionFactory?.audioTrack(with: audioSource!, trackId: self.kAudioTrackId)

        if let audioTrack = self.localAudioTrack {
            self.localStream?.addAudioTrack(audioTrack)
            
            /// Add the local audio track to the peer connection
            debugger("WebRTC: Adding audio track to our peer connection.")
            self.localAudioSender = self.peerConnection?.add(audioTrack, streamIds: [self.kStreamId])
            if self.localAudioSender == nil {
                debugger("** ERROR: Failed to add audio track")
            }
        }
    }
    
    /// Create local video track and add it to the peer connection
    private func createVideoSender() {
        let videoSource = self.peerConnectionFactory?.videoSource()
        #if !targetEnvironment(simulator)
        /// Camera capture only works on the device, not the simulator
        self.localCapture = RTCCameraVideoCapturer(delegate: videoSource!)
        self.delegate?.onLocalCaptureCreate?(self, self.localCapture!)
        self.startLocalCapture()
        #endif
        
        self.localVideoTrack = self.peerConnectionFactory?.videoTrack(with: videoSource!, trackId: self.kVideoTrackId)
        if let videoTrack = self.localVideoTrack {
            self.localStream?.addVideoTrack(videoTrack)
            
            /// Add the local video track to the peer connection
            debugger("WebRTC: Adding video track to our peer connection")
            self.localVideoSender = self.peerConnection?.add(videoTrack, streamIds: [self.kStreamId])
            if self.localVideoSender == nil {
                debugger("** ERROR: Failed to add video track")
            }
        }
        
        #if !NIN_USE_PLANB_SEMANTICS
        /// Set up remote rendering; once the video frames are received, the video will commence
        if let remoteVideoTrack = self.videoTransceiver?.receiver.track as? RTCVideoTrack {
            self.delegate?.onRemoteVideoTrackReceive?(self, remoteVideoTrack)
        }
        #endif
    }
}

/// Force the audio output to Speaker. Look at issue #61 for `NinchatSDK`
extension NINChatWebRTCClientImpl {
    /// The issue with the output: `https://github.com/somia/ninchat-sdk-ios/issues/61` and `https://github.com/somia/mobile/issues/302`
    /// `https://stackoverflow.com/questions/24595579/how-to-redirect-audio-to-speakers-in-the-apprtc-ios-example`
    @objc
    private func didSessionRouteChange(_ notification: Notification) {
        if let userInfo = notification.userInfo, let reasonKey = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt, let reason = AVAudioSession.RouteChangeReason(rawValue: reasonKey) {
            print("Route Changed: \(userInfo)")
            
            /// Force Speaker in case the app tries to use earning as the output
            if RTCAudioSession.sharedInstance().currentRoute.outputs.first?.portType.rawValue ?? "" == "Receiver" || AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType.rawValue ?? "" == "Receiver" {
                RTCAudioSession.sharedInstance().lockForConfiguration()
                if reason == .categoryChange {
                    do {
                        try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                        try RTCAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                    } catch {
                        debugger("WebRTC: Failed to change the output to device's speaker - `didSessionRouteChange(_:)`: \(error)")
                    }
                }
                RTCAudioSession.sharedInstance().unlockForConfiguration()
            }
        }
    }
}

extension NINChatWebRTCClientImpl: RTCPeerConnectionDelegate {
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugger("WebRTC: Received stream \(stream.streamId) with \(stream.videoTracks.count) video tracks and \(stream.audioTracks.count) audio tracks")
        
        #if NIN_USE_PLANB_SEMANTICS
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                self.delegate?.onRemoteVideoTrackReceive?(self, track)
            }
            debugger("** ERROR: no video tracks in `didAddStream:`")
        }
        #endif
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        if let track = transceiver.receiver.track {
            debugger("WebRTC: Now receiving \(track.kind) on track \(track.trackId).")
        }
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugger("WebRTC: removed stream: \(stream)")
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugger("WebRTC: opened data channel: \(dataChannel)")
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        DispatchQueue.main.async {
            _ = try? self.sessionManager?.send(type: .candidate, payload: ["candidate":candidate.toDictionary]) { error in
                if let error = error { debugger("WebRTC: ERROR: Failed to send ICE candidate: \(error)") }
            }
        }
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        let newConnectionState = ConnectionState(rawValue: newState.rawValue)!
        debugger("WebRTC: ICE connection state changed: \(newConnectionState.description)")
        
        DispatchQueue.main.async {
            self.delegate?.onConnectionStateChange?(self, newConnectionState)
        }
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugger("WebRTC: ICE gathering state changed: \(GatheringState(rawValue: newState.rawValue)!.description)")
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugger("WebRTC: ICE signaling state changed: \(SignalingState(rawValue: stateChanged.rawValue)!.description)")
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugger("WebRTC: Removed ICE candidates: \(candidates)")
    }
    
    internal func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        /// TODO see:
        /// https://stackoverflow.com/questions/31165316/webrtc-renegotiate-the-peer-connection-to-switch-streams
        /// https://stackoverflow.com/questions/29511602/how-to-exchange-streams-from-two-peerconnections-with-offer-answer/29530757#29530757
        debugger("WebRTC: **WARNING** renegotiation needed - unimplemented!")
    }
}
