//
//  NINUserTypingMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 27/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINChatMessage.h"

@class NINChannelUser;

NS_ASSUME_NONNULL_BEGIN

/** Placeholder chat 'message' that indicates that another user is typing. */
@interface NINUserTypingMessage : NSObject <NINChatMessage>

/** The chat user currently typing. */
@property (nonatomic, strong, readonly) NINChannelUser* user;

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

+(instancetype) messageWithUser:(NINChannelUser*)user timestamp:(NSDate*)timestamp;

@end

NS_ASSUME_NONNULL_END
