//
//  NINMessageThrottler.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/11/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@import NinchatLowLevelClient;

NS_ASSUME_NONNULL_BEGIN

@interface NINInboundMessage: NSObject

@property (nonatomic, strong, readonly) NINLowLevelClientProps* params;
@property (nonatomic, strong, readonly) NINLowLevelClientPayload* payload;
@property (nonatomic, strong, readonly) NSDate* created;
@property (nonatomic, strong, readonly) NSString* messageId;

+(instancetype) messageWithParams:(NINLowLevelClientProps*)params andPayload:(NINLowLevelClientPayload*)payload;

@end

typedef void (^messageThrottlerMessageReadyCallback)(NINInboundMessage* message);

/**
 Implements a simple message queue where the messages are ordered by their message_id property.
 The messages stay in the queue for a short time (<< 1 second) and then get sent to the UI.
 This exists so that the message order remains intact as messages may arrive out of order.
 */
@interface NINMessageThrottler : NSObject

@property (nonatomic, copy) messageThrottlerMessageReadyCallback messageReadyCallback;

+(instancetype) throttlerWithCallback:(messageThrottlerMessageReadyCallback)messageReadyCallback;
-(void) addMessage:(NINInboundMessage*)message;
-(void) stop; 

@end

NS_ASSUME_NONNULL_END
