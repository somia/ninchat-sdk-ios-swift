//
//  NINChannelMessage.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 06/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINChatMessage.h"

@class NINChannelUser;

/** Represents a chat message on a channel. */
@protocol NINChannelMessage<NINChatMessage>

/** Message ID. */
@property (nonatomic, strong, readonly) NSString* messageID;

/** Whether this message is sent by the mobile user (this device). */
@property (nonatomic, assign, readonly) BOOL mine;

/**
 * YES if this message is a part in a series, ie. the sender of the previous message
 * also sent this message.
 */
@property (nonatomic, assign) BOOL series;

/** The message sender. */
@property (nonatomic, strong, readonly) NINChannelUser* sender;

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

@end
