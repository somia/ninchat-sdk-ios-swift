//
//  NINWebRTCClient.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebRTC;

#import "NINPrivateTypes.h"

@class NINSessionManager;
@class NINWebRTCServerInfo;
@class NINWebRTCClient;

/**
 * Delegate protocol for NINWebRTCClient. All the methods are called on the main thread.
 */
@protocol NINWebRTCClientDelegate <NSObject>

/** Connection state was changed. */
-(void) webrtcClient:(NINWebRTCClient*)client didChangeConnectionState:(RTCIceConnectionState)newState;

/** A local video capturer was created. */
-(void) webrtcClient:(NINWebRTCClient*)client didCreateLocalCapturer:(RTCCameraVideoCapturer*)localCapturer;

/** A new remote video track was initiated. */
-(void) webrtcClient:(NINWebRTCClient*)client didReceiveRemoteVideoTrack:(RTCVideoTrack*)remoteVideoTrack;

/** An unrecoverable error occurred. */
-(void) webrtcClient:(NINWebRTCClient*)client didGetError:(NSError*)error;

@end

/**
 * WebRTC client.
 */
@interface NINWebRTCClient : NSObject

/** Client delegate for receiving video tracks and other updates. */
@property (nonatomic, weak) id<NINWebRTCClientDelegate> delegate;

/** Disconnects the client. The client is unusable after calling this method. */
-(void) disconnect;

/** Starts the client, with optional SDP (Service Description Protocol) data. */
-(void) startWithSDP:(NSDictionary*)sdp;

-(BOOL) muteLocalAudio;
-(BOOL) unmuteLocalAudio;
-(BOOL) disableLocalVideo;
-(BOOL) enableLocalVideo;

/** Creates a new client. */
+(instancetype) clientWithSessionManager:(NINSessionManager*)sessionManager operatingMode:(NINWebRTCClientOperatingMode)operatingMode stunServers:(NSArray<NINWebRTCServerInfo*>*)stunServers turnServers:(NSArray<NINWebRTCServerInfo*>*)turnServers;

@end
