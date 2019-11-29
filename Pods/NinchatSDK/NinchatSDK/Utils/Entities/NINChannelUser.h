//
//  NINChannelUser.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 30/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Represents a chat user on a channel. */
@interface NINChannelUser : NSObject

/** User's ID. */
@property (nonatomic, strong, readonly) NSString* userID;

/** User's real name. */
@property (nonatomic, strong, readonly) NSString* realName;

/** User's display name. */
@property (nonatomic, strong, readonly) NSString* displayName;

/** User's icon url. */
@property (nonatomic, strong, readonly) NSString* iconURL;

/** Whether the user is a Guest user. */
@property (nonatomic, assign, readonly) BOOL guest;

/** Creates a new user. */
+(NINChannelUser*) userWithID:(NSString*)userID realName:(NSString*)realName displayName:(NSString*)displayName iconURL:(NSString*)iconURL guest:(BOOL)guest;

@end
