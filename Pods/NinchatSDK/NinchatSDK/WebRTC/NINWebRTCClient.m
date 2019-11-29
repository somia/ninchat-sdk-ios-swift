//
//  NINWebRTCClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import AVFoundation;

#import "RTCSessionDescription+Dictionary.h"
#import "RTCICECandidate+Dictionary.h"

#import "NINSessionManager.h"
#import "NINWebRTCClient.h"
#import "NINWebRTCServerInfo.h"
#import "NINUtils.h"
#import "NINToast.h"

// See the WebRTC signaling diagram:
// https://mdn.mozillademos.org/files/12363/WebRTC%20-%20Signaling%20Diagram.svg
//
// See the iOS AppARD example implementation:
// https://webrtc.googlesource.com/src/+/master/examples/objc/AppRTCMobile/ARDAppClient.m

// Define this to use the legacy implementation-supporting PlanB SDP semantics
//#define NIN_USE_PLANB_SEMANTICS 1

// RTC stream / track IDs
static NSString* const kStreamId = @"NINAMS";
static NSString* const kAudioTrackId = @"NINAMSa0";
static NSString* const kVideoTrackId = @"NINAMSv0";

@interface NINWebRTCClient () <RTCPeerConnectionDelegate>

// Session manager, used for signaling
@property (nonatomic, weak) NINSessionManager* sessionManager;

// Operation mode; caller or callee.
@property (nonatomic, assign) NINWebRTCClientOperatingMode operatingMode;

// Factory for creating our RTC peer connections
@property (nonatomic, strong) RTCPeerConnectionFactory* peerConnectionFactory;

// List of our ICE servers (STUN, TURN)
@property (nonatomic, strong) NSMutableArray<RTCIceServer*>* iceServers;

// Current RTC peer connection if any
@property (nonatomic, strong) RTCPeerConnection* peerConnection;

// NSNotificationCenter observer for WebRTC signaling events from session manager
@property (nonatomic, strong) id<NSObject> signalingObserver;

// Local video capturer
@property (nonatomic, strong) RTCCameraVideoCapturer* localCapturer;

// Local media stream
@property (nonatomic, strong) RTCMediaStream* localStream;

// Default local audio track
//@property(nonatomic, strong) RTCAudioTrack* defaultLocalAudioTrack;

// Default local video track
//@property(nonatomic, strong) RTCVideoTrack* defaultLocalVideoTrack;

// Local audio/video tracks
@property (nonatomic, strong) RTCAudioTrack* localAudioTrack;
@property (nonatomic, strong) RTCVideoTrack* localVideoTrack;

// RTP senders for local audio/video tracks
@property (nonatomic, strong) RTCRtpSender* localAudioSender;
@property (nonatomic, strong) RTCRtpSender* localVideoSender;

// Mapping for the ICE signaling state --> state name
@property (nonatomic, strong) NSDictionary<NSNumber*, NSString*>* iceSignalingStates;

// Mapping for the ICE connection state --> state name
@property (nonatomic, strong) NSDictionary<NSNumber*, NSString*>* iceConnectionStates;

// Mapping for the ICE gathering state --> state name
@property (nonatomic, strong) NSDictionary<NSNumber*, NSString*>* iceGatheringStates;

@end

@implementation NINWebRTCClient

#pragma mark - Private Methods

#ifndef NIN_USE_PLANB_SEMANTICS
-(RTCRtpTransceiver*) videoTransceiver {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    for (RTCRtpTransceiver* transceiver in self.peerConnection.transceivers) {
        if (transceiver.mediaType == RTCRtpMediaTypeVideo) {
            return transceiver;
        }
    }

    return nil;
}
#endif

-(RTCMediaConstraints*) defaultOfferOrAnswerConstraints {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    NSDictionary<NSString*, NSString*>* mandatoryConstraints = @{@"OfferToReceiveAudio": @"true", @"OfferToReceiveVideo": @"true"};

    return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
}

-(void) startLocalCapture {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    AVCaptureDevice* device = [self findCaptureDeviceForPosition:position];
    NSCAssert(device != nil, @"Failed to find device");
    AVCaptureDeviceFormat* format = [self selectFormatForDevice:device];

    if (format == nil) {
        [self.sessionManager.ninchatSession sdklog:@"** ERROR No valid formats for device %@", device];
        return;
    }

    NSLog(@"Starting local video capturing..");

//    [self.localCapturer startCaptureWithDevice:device format:format fps:[self selectFpsForFormat:format]];

    NSInteger fps = [self selectFpsForFormat:format];
    NSLog(@"Using FPS: %ld for local capture", (long)fps);

    [self.localCapturer startCaptureWithDevice:device format:format fps:fps completionHandler:^(NSError * _Nonnull error) {
        if (error != nil) {
            [self.sessionManager.ninchatSession sdklog:@"** ERROR failed to start local capture: %@", error];
            return;
        }

        NSLog(@"Local capture started OK.");
    }];
}

-(void) stopLocalCapture {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    NSLog(@"Stopping local video capturing..");
    [self.localCapturer stopCapture];
}

-(AVCaptureDevice*) findCaptureDeviceForPosition:(AVCaptureDevicePosition)position {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    NSArray<AVCaptureDevice*>* captureDevices = [RTCCameraVideoCapturer captureDevices];

    for (AVCaptureDevice* device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }

    return captureDevices[0];
}

-(AVCaptureDeviceFormat*) selectFormatForDevice:(AVCaptureDevice*)device {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    NSArray<AVCaptureDeviceFormat*>* formats = [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    AVCaptureDeviceFormat* selectedFormat = formats.firstObject;

    // We will try to find closest match for this video dimension
    CGSize targetDimension = CGSizeMake(640, 480);
    NSInteger currentDiff = INT_MAX;

    for (AVCaptureDeviceFormat* format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        FourCharCode pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription);

        int diff = fabs(targetDimension.width - dimension.width) + fabs(targetDimension.width - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        } else if (diff == currentDiff && pixelFormat == [self.localCapturer preferredOutputPixelFormat]) {
            selectedFormat = format;
        }
    }

    NSLog(@"Selected video format: %@", selectedFormat.formatDescription);

    return selectedFormat;
}

-(NSInteger) selectFpsForFormat:(AVCaptureDeviceFormat*)format {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    Float64 maxSupportedFramerate = 0;

    for (AVFrameRateRange* fpsRange in format.videoSupportedFrameRateRanges) {
        maxSupportedFramerate = fmax(maxSupportedFramerate, fpsRange.maxFrameRate);
    }

    return fmin(maxSupportedFramerate, 30);
}

-(RTCVideoTrack*) createLocalVideoTrack {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    RTCVideoSource* videoSource = [self.peerConnectionFactory videoSource];

#if !TARGET_IPHONE_SIMULATOR
    // Camera capture only works on the device, not the simulator
    self.localCapturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
    [self.delegate webrtcClient:self didCreateLocalCapturer:self.localCapturer];
    [self startLocalCapture];
#endif

    return [self.peerConnectionFactory videoTrackWithSource:videoSource trackId:kVideoTrackId];
}

-(void) createMediaSenders {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");

    NSLog(@"WebRTC: Configuring local audio & video sources");

    // Create local audio track and add it to the peer connection
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    RTCAudioSource* audioSource = [self.peerConnectionFactory audioSourceWithConstraints:constraints];
    self.localAudioTrack = [self.peerConnectionFactory audioTrackWithSource:audioSource
                                                                         trackId:kAudioTrackId];

//    NSLog(@"localAudioTrack: %@", localAudioTrack);
    [self.localStream addAudioTrack:self.localAudioTrack];

    NSLog(@"WebRTC: Adding audio track to our peer connection.");
    self.localAudioSender = [self.peerConnection addTrack:self.localAudioTrack streamIds:@[kStreamId]];
    if (self.localAudioSender == nil) {
        NSLog(@"** ERROR: Failed to add audio track");
    }

    // Create local video track
    self.localVideoTrack = [self createLocalVideoTrack];
    if (self.localVideoTrack != nil) {
//        NSLog(@"localVideoTrack: %@", localVideoTrack);
        [self.localStream addVideoTrack:self.localVideoTrack];

        // Add the local video track to the peer connection
        NSLog(@"WebRTC: Adding video track to our peer connection.");
        self.localVideoSender = [self.peerConnection addTrack:self.localVideoTrack streamIds:@[kStreamId]];
        if (self.localVideoSender == nil) {
            NSLog(@"** ERROR: Failed to add video track");
        }

#ifndef NIN_USE_PLANB_SEMANTICS
        // Set up remote rendering; once the video frames are received, the video will commence
        RTCVideoTrack* remoteVideoTrack = (RTCVideoTrack*)(self.videoTransceiver.receiver.track);
        if (remoteVideoTrack == nil) {
            NSLog(@"** ERROR: got nil remotevideo track from tranceiver!");
        }
        [self.delegate webrtcClient:self didReceiveRemoteVideoTrack:remoteVideoTrack];
#endif
    }

    NSLog(@"WebRTC: Local media senders configured.");
}

-(void) didCreateSessionDescription:(RTCSessionDescription*)sdp error:(NSError*)error {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

    NSLog(@"didCreateSessionDescription: error: %@", error);

    if (error != nil) {
        NSLog(@"WebRTC: got create session error: %@", error);
        [self disconnect];
        [self.delegate webrtcClient:self didGetError:error];
        return;
    }

    __weak typeof(self) weakSelf = self;

    NSLog(@"Setting local description");
    [self.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
        runOnMainThread(^{
            [weakSelf didSetSessionDescription:error];
        });
    }];

    // Decide what type of signaling message to send based on the SDP type
    NSDictionary* typeMap = @{@(RTCSdpTypeOffer): kNINMessageTypeWebRTCOffer, @(RTCSdpTypeAnswer): kNINMessageTypeWebRTCAnswer};
    NSString* messageType = typeMap[@(sdp.type)];
    if (messageType == nil) {
        NSLog(@"WebRTC: Unknown SDP type: %ld", (long)sdp.type);
        return;
    }

    NSLog(@"Sending RTC signaling message of type: %@", messageType);

    // Send signaling message about the offer/answer
    [self.sessionManager sendMessageWithMessageType:messageType payloadDict:@{@"sdp": sdp.dictionary} completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"WebRTC: Message send error: %@", error);
            [NINToast showWithErrorMessage:@"Failed to send RTC signaling message" callback:nil];
        }
    }];
}

-(void) didSetSessionDescription:(NSError*)error {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

    NSLog(@"didSetSessionDescription: error: %@", error);

    if (error != nil) {
        NSLog(@"WebRTC: got set session error: %@", error);
        [self disconnect];
        [self.delegate webrtcClient:self didGetError:error];
        return;
    }

    __weak typeof(self) weakSelf = self;

    if ((self.operatingMode == NINWebRTCClientOperatingModeCallee) && (self.peerConnection.localDescription == nil)) {

        NSLog(@"WebRTC: Creating answer");

        RTCMediaConstraints* constraints = [self defaultOfferOrAnswerConstraints];
        [self.peerConnection answerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            runOnMainThread(^{
                [weakSelf didCreateSessionDescription:sdp error:error];
            });
        }];
    }
}

#pragma mark - Public Methods

-(void) disconnect {
    [self.sessionManager.ninchatSession sdklog:@"WebRTC Client disconnecting."];

    [self stopLocalCapture];
    self.localCapturer = nil;

    self.localStream = nil;
    
    if (self.peerConnection != nil) {
        [self.peerConnection close];
        self.peerConnection = nil;
    }

//    self.defaultLocalAudioTrack = nil;
//    self.defaultLocalVideoTrack = nil;

    self.localAudioSender = nil;
    self.localVideoSender = nil;
    self.localAudioTrack = nil;
    self.localVideoTrack = nil;

    self.peerConnectionFactory = nil;
    self.sessionManager = nil;
    self.iceServers = nil;
    
    [NSNotificationCenter.defaultCenter removeObserver:self.signalingObserver];
    self.signalingObserver = nil;
}

-(void) startWithSDP:(NSDictionary*)sdp {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread!");
    NSCAssert(self.peerConnectionFactory != nil, @"Invalid state - client was disconnected?");
    NSCAssert(self.sessionManager != nil, @"Invalid state - client was disconnected?");
    NSCAssert(self.signalingObserver == nil, @"Cannot have active observer already");

    NSLog(@"WebRTC: Starting..");

    __weak typeof(self) weakSelf = self;

    // Start listening to WebRTC signaling messages from the chat session manager
    self.signalingObserver = fetchNotification(kNINWebRTCSignalNotification, ^BOOL(NSNotification* note) {
        NSDictionary* payload = note.userInfo[@"payload"];

        if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCIceCandidate]) {
            NSDictionary* candidateDict = payload[@"candidate"];
            RTCIceCandidate* candidate = [RTCIceCandidate fromDictionary:candidateDict];
            [weakSelf.peerConnection addIceCandidate:candidate];
        } else if ([note.userInfo[@"messageType"] isEqualToString:kNINMessageTypeWebRTCAnswer]) {
            RTCSessionDescription* description = [RTCSessionDescription fromDictionary:payload[@"sdp"]];
            NSCAssert(description != nil, @"Session description cannot be null");
            NSLog(@"Setting remote description from Answer with SDP: %@", description);

            [weakSelf.peerConnection setRemoteDescription:description completionHandler:^(NSError * _Nullable error) {
                runOnMainThread(^{
                    [weakSelf didSetSessionDescription:error];
                });
            }];
        }

        return NO;
    });

    // Configure & create our RTC peer connection
    NSLog(@"Configuring & initializing RTC Peer Connectiong");
    NSDictionary<NSString*, NSString*>* optionalConstraints = @{@"DtlsSrtpKeyAgreement": @"true"};
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];

    RTCConfiguration* configuration = [[RTCConfiguration alloc] init];
    configuration.iceServers = self.iceServers;
#ifdef NIN_USE_PLANB_SEMANTICS
    NSLog(@"WebRTC: Configuring peer connection for PlanB SDP semantics.");
    configuration.sdpSemantics = RTCSdpSemanticsPlanB; // <-- Legacy RTC impl support
#else
    NSLog(@"WebRTC: Configuring peer connection for Unified Plan SDP semantics.");
    configuration.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
#endif

    self.peerConnection = [self.peerConnectionFactory peerConnectionWithConfiguration:configuration constraints:constraints delegate:self];

    // Create a stream object; this is used to group the audio/video tracks together.
    self.localStream = [self.peerConnectionFactory mediaStreamWithStreamId:kStreamId];

    // Set up the local audio & video sources / tracks
    [self createMediaSenders];

    if (self.operatingMode == NINWebRTCClientOperatingModeCaller) {
        // We are the 'caller', ie. the connection initiator; create a connection offer
        NSLog(@"WebRTC: making a call.");
        [self.peerConnection offerForConstraints:[self defaultOfferOrAnswerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            NSLog(@"Created SDK offer with error: %@", error);

            runOnMainThread(^{
                [weakSelf didCreateSessionDescription:sdp error:error];
            });
        }];
    } else {
        // We are the 'callee', ie. we are answering.
        NSCAssert(sdp != nil, @"Must have Offer SDP data");

        NSLog(@"WebRTC: answering a call.");

        RTCSessionDescription* description = [RTCSessionDescription fromDictionary:sdp];

        NSLog(@"Setting remote description from Offer.");
        [self.peerConnection setRemoteDescription:description completionHandler:^(NSError * _Nullable error) {
            runOnMainThread(^{
                [weakSelf didSetSessionDescription:error];
            });
        }];
    }
}

-(BOOL) muteLocalAudio {
    if ((self.localAudioTrack == nil) || !self.localAudioTrack.isEnabled) {
        NSLog(@"** ERROR: muteLocalAudio prerequisites not filled.");
    }

    self.localAudioTrack.isEnabled = NO;
    return YES;
}

-(BOOL) unmuteLocalAudio {
    if ((self.localAudioTrack == nil) || self.localAudioTrack.isEnabled) {
        NSLog(@"** ERROR: unmuteLocalAudio prerequisites not filled.");
    }

    self.localAudioTrack.isEnabled = YES;
    return YES;
}

-(BOOL) disableLocalVideo {
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    // Camera capture only works on the device, not the simulator
    if ((self.localVideoTrack == nil) || !self.localVideoTrack.isEnabled) {
        NSLog(@"** ERROR: disableLocalVideo prerequisities not filled.");
        return NO;
    }

    self.localVideoTrack.isEnabled = NO;
    return YES;
#else
    return YES;
#endif
}

-(BOOL) enableLocalVideo {
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    // Camera capture only works on the device, not the simulator
    if ((self.localVideoTrack == nil) || self.localVideoTrack.isEnabled) {
        NSLog(@"** ERROR: enableLocalVideo prerequisities not filled.");
        return NO;
    }

    self.localVideoTrack.isEnabled = YES;
    return YES;
#else
    return YES;
#endif
}

#pragma mark - From RTCPeerConnectionDelegate

-(void) peerConnection:(nonnull RTCPeerConnection *)peerConnection didAddStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"WebRTC: Received stream %@ with %lu video tracks and %lu audio tracks", stream.streamId, (unsigned long)stream.videoTracks.count, (unsigned long)stream.audioTracks.count);

#ifdef NIN_USE_PLANB_SEMANTICS
    runOnMainThread(^{
        if (stream.videoTracks.count > 0) {
            [self.delegate webrtcClient:self didReceiveRemoteVideoTrack:stream.videoTracks[0]];
        } else {
            NSLog(@"** ERROR: no video tracks in didAddStream:");
        }
    });
#endif
}

-(void) peerConnection:(RTCPeerConnection*)peerConnection didStartReceivingOnTransceiver:(RTCRtpTransceiver*)transceiver {
    RTCMediaStreamTrack* track = transceiver.receiver.track;
    NSLog(@"WebRTC: Now receiving %@ on track %@.", track.kind, track.trackId);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"WebRTC: removed stream: %@", stream);
}

-(void) peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel {
    NSLog(@"WebRTC: opened data channel: %@", dataChannel);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didGenerateIceCandidate:(nonnull RTCIceCandidate *)candidate {
//    NSLog(@"WebRTC: Generated ICE candidate: %@", candidate.dictionary);

    runOnMainThread(^{
        [self.sessionManager sendMessageWithMessageType:kNINMessageTypeWebRTCIceCandidate payloadDict:@{@"candidate": candidate.dictionary} completion:^(NSError* error) {
            if (error != nil) {
                NSLog(@"WebRTC: ERROR: Failed to send ICE candidate: %@", error);
                return;
            }
//            NSLog(@"ICE candidate sent to remote Ninchat API.");
        }];
    });
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"WebRTC: ICE connection state changed: %ld (%@)", (long)newState, self.iceConnectionStates[@(newState)]);

    runOnMainThread(^{
        [self.delegate webrtcClient:self didChangeConnectionState:newState];
    });
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    NSLog(@"WebRTC: ICE gathering state changed: %ld (%@)", (long)newState, self.iceGatheringStates[@(newState)]);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    NSLog(@"WebRTC: ICE signaling state changed: %ld (%@)", (long)stateChanged, self.iceSignalingStates[@(stateChanged)]);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"WebRTC: Removed ICE candidates: %@", candidates);
}

- (void)peerConnectionShouldNegotiate:(nonnull RTCPeerConnection *)peerConnection {
    //TODO see:
    // https://stackoverflow.com/questions/31165316/webrtc-renegotiate-the-peer-connection-to-switch-streams
    // https://stackoverflow.com/questions/29511602/how-to-exchange-streams-from-two-peerconnections-with-offer-answer/29530757#29530757
    //    NSLog(@"WebRTC: **WARNING** renegotiation needed - unimplemented!");
}

#pragma mark - Initializers

+(instancetype) clientWithSessionManager:(NINSessionManager*)sessionManager operatingMode:(NINWebRTCClientOperatingMode)operatingMode stunServers:(NSArray<NINWebRTCServerInfo*>*)stunServers turnServers:(NSArray<NINWebRTCServerInfo*>*)turnServers {

    [sessionManager.ninchatSession sdklog:@"Creating new NINWebRTCClient in the %@ mode", (operatingMode == NINWebRTCClientOperatingModeCaller) ? @"CALLER" : @"CALLEE"];

    NINWebRTCClient* client = [NINWebRTCClient new];
    client.sessionManager = sessionManager;
    client.operatingMode = operatingMode;

    RTCDefaultVideoDecoderFactory* decoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];
    RTCDefaultVideoEncoderFactory* encoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];
    client.peerConnectionFactory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory
                                                                             decoderFactory:decoderFactory];

    client.iceServers = [NSMutableArray arrayWithCapacity:(stunServers.count + turnServers.count)];

    for (NINWebRTCServerInfo* serverInfo in stunServers) {
        [client.iceServers addObject:serverInfo.iceServer];
    }

    for (NINWebRTCServerInfo* serverInfo in turnServers) {
        [client.iceServers addObject:serverInfo.iceServer];
    }

    client.iceSignalingStates = @{@(RTCSignalingStateStable): @"RTCSignalingStateStable",
                                  @(RTCSignalingStateHaveLocalOffer): @"RTCSignalingStateHaveLocalOffer",
                                  @(RTCSignalingStateHaveLocalPrAnswer): @"RTCSignalingStateHaveLocalPrAnswer",
                                  @(RTCSignalingStateHaveRemoteOffer): @"RTCSignalingStateHaveRemoteOffer",
                                  @(RTCSignalingStateHaveRemotePrAnswer): @"RTCSignalingStateHaveRemotePrAnswer",
                                  @(RTCSignalingStateClosed): @"RTCSignalingStateClosed"};

    client.iceConnectionStates = @{@(RTCIceConnectionStateNew): @"RTCIceConnectionStateNew",
                                   @(RTCIceConnectionStateChecking): @"RTCIceConnectionStateChecking",
                                   @(RTCIceConnectionStateConnected): @"RTCIceConnectionStateConnected",
                                   @(RTCIceConnectionStateCompleted): @"RTCIceConnectionStateCompleted",
                                   @(RTCIceConnectionStateFailed): @"RTCIceConnectionStateFailed",
                                   @(RTCIceConnectionStateDisconnected): @"RTCIceConnectionStateDisconnected",
                                   @(RTCIceConnectionStateClosed): @"RTCIceConnectionStateClosed",
                                   @(RTCIceConnectionStateCount): @"RTCIceConnectionStateCount"};

    client.iceGatheringStates = @{@(RTCIceGatheringStateNew): @"RTCIceGatheringStateNew",
                                  @(RTCIceGatheringStateGathering): @"RTCIceGatheringStateGathering",
                                  @(RTCIceGatheringStateComplete): @"RTCIceGatheringStateComplete"};

    return client;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
