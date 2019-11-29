//
//  RTCSessionDescription+JSON.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 20/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import WebRTC;

/**
 * Methods for converting RTCSessionDescription to / from dictionary representation.
 *
 * The dictionary format is compatible with JSON encoding of the object.
 */
@interface RTCSessionDescription (Dictionary)

-(NSDictionary*) dictionary;
+(RTCSessionDescription*) fromDictionary:(NSDictionary*)dictionary;

@end
