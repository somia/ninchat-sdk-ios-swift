//
//  RTCICECandidate+Dictionary.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 20/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "RTCICECandidate+Dictionary.h"

static NSString* const kKeyCandidate = @"candidate";
static NSString* const kKeySdpMLineIndex = @"sdpMLineIndex";
static NSString* const kKeySdpMid = @"sdpMid";

@implementation RTCIceCandidate (Dictionary)

-(NSDictionary*) dictionary {
    return @{kKeySdpMLineIndex: @(self.sdpMLineIndex), kKeySdpMid: self.sdpMid, kKeyCandidate: self.sdp};
}

+(RTCIceCandidate*) fromDictionary:(NSDictionary*)dictionary {
    if (dictionary == nil) {
        NSLog(@"** ERROR: Trying to create RTCIceCandidate from nil dictionary!");
        return nil;
    }

    NSString* candidate = dictionary[kKeyCandidate];
    if (candidate == nil) {
        NSLog(@"** ERROR: missing '%@' key in dictionary for RTCIceCandidate", kKeyCandidate);
    }

    NSNumber* lineIndex = dictionary[kKeySdpMLineIndex];
    if (lineIndex == nil) {
        NSLog(@"** ERROR: missing '%@' key in dictionary for RTCIceCandidate", kKeySdpMLineIndex);
    }

    NSString* sdpMid = dictionary[kKeySdpMid];
    if (sdpMid == nil) {
        NSLog(@"** ERROR: missing '%@' key in dictionary for RTCIceCandidate", kKeySdpMid);
    }

    return [[RTCIceCandidate alloc] initWithSdp:candidate sdpMLineIndex:lineIndex.intValue sdpMid:sdpMid];
}

@end
