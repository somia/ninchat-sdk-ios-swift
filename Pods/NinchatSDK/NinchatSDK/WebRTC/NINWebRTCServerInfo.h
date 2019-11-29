//
//  NINWebRTCServerInfo.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTCIceServer;

/**
 * Represents a (STUN / TURN) server.
 */
@interface NINWebRTCServerInfo : NSObject

@property (nonatomic, strong, readonly) NSString* url;
@property (nonatomic, strong, readonly) NSString* username;
@property (nonatomic, strong, readonly) NSString* credential;

+(NINWebRTCServerInfo*) serverWithURL:(NSString*)url username:(NSString*)username credential:(NSString*)credential;

-(RTCIceServer*) iceServer;

@end
