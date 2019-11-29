//
//  NINMessageThrottler.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/11/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINMessageThrottler.h"

// Timer ticks this often
const NSTimeInterval kTimerTickInterval = 0.05;

// Max age of a message in the list before it is submitted
const NSTimeInterval kMessageMaxAge = 1.0;

#pragma mark - NINInboundMessage

@interface NINInboundMessage ()

// Mutable versions of the properties
@property (nonatomic, strong) NINLowLevelClientProps* params;
@property (nonatomic, strong) NINLowLevelClientPayload* payload;
@property (nonatomic, strong) NSDate* created;
@property (nonatomic, strong) NSString* messageId;

@end

@implementation NINInboundMessage

+(instancetype) messageWithParams:(NINLowLevelClientProps*)params andPayload:(NINLowLevelClientPayload*)payload {
    
    NINInboundMessage* msg = [NINInboundMessage new];
    msg.params = params;
    msg.payload = payload;
    msg.created = [NSDate date];
    
    NSError* error = nil;
    msg.messageId = [params getString:@"message_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");
    
    return msg;
}

@end

#pragma mark - NINMessageThrottler

@interface NINMessageThrottler () {
    NSMutableArray<NINInboundMessage*>* _messages;
    NSTimer* _timer;
};

@end

@implementation NINMessageThrottler

+(instancetype) throttlerWithCallback:(messageThrottlerMessageReadyCallback)messageReadyCallback {
    NINMessageThrottler* t = [NINMessageThrottler new];
    t->_messages = [NSMutableArray arrayWithCapacity:10];
    t.messageReadyCallback = messageReadyCallback;
    
    return t;
}

-(void) timerTick {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
    NSCAssert(_messages.count > 0, @"Timer should not be running");
    
    NSMutableArray* msgsSent = nil;
    
    // Send all messages older than the defined max age
    for (NSInteger i = 0; i < _messages.count; i++) {
        NINInboundMessage* msg = _messages[i];
        
        if (-[msg.created timeIntervalSinceNow] > kMessageMaxAge) {
            if (msgsSent.count == 0) {
                msgsSent = [NSMutableArray arrayWithCapacity:10];
            }
            
            self.messageReadyCallback(msg);
            [msgsSent addObject:msg];
        }
    }

    [_messages removeObjectsInArray:msgsSent];
    
    if (_messages.count == 0) {
        [_timer invalidate];
        _timer = nil;
    }
}

-(void) startTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)kTimerTickInterval target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
}

-(void) stopTimer {
    [_timer invalidate];
    _timer = nil;
}

-(void) stop {
    [self stopTimer];
    [_messages removeAllObjects];
}

-(void) addMessage:(NINInboundMessage*)message {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

    // Insert the message into the list of messages by its ID
    NSInteger insertionIndex = -1;
    for (NSInteger i = 0; i < _messages.count; i++) {
        if ([message.messageId compare:_messages[i].messageId] != NSOrderedDescending) {
            // Message id precedes (or is same as) the i:th entry in the list; insert it here
            insertionIndex = i;
            break;
        }
    }

    if (insertionIndex == -1) {
        if (_messages.count == 0) {
            // List is empty; insert at the top as the only entry
            insertionIndex = 0;
        } else {
            // Message ID was greater than all the entries in the list; insert to the end of the list
            insertionIndex = _messages.count;
        }
    }
    
    NSCAssert(insertionIndex >= 0 && insertionIndex <= _messages.count, @"Invalid insertion index");
    
    [_messages insertObject:message atIndex:insertionIndex];
    
    if (_timer == nil) {
        [self startTimer];
    }
}

@end
