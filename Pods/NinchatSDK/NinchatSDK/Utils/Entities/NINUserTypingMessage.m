//
//  NINUserTypingMessage.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 27/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINUserTypingMessage.h"

@interface NINUserTypingMessage ()

@property (nonatomic, strong) NINChannelUser* user;
@property (nonatomic, strong) NSDate* timestamp;

@end

@implementation NINUserTypingMessage

+(instancetype) messageWithUser:(NINChannelUser*)user timestamp:(NSDate*)timestamp {
    NINUserTypingMessage* msg = [NINUserTypingMessage new];
    msg.user = user;
    msg.timestamp = timestamp;

    return msg;
}

@end
