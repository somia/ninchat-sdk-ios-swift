//
//  NINChannelUser.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 30/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChannelUser.h"

@interface NINChannelUser ()

@property (nonatomic, strong) NSString* userID;
@property (nonatomic, strong) NSString* realName;
@property (nonatomic, strong) NSString* displayName;
@property (nonatomic, strong) NSString* iconURL;
@property (nonatomic, assign) BOOL guest;

@end

@implementation NINChannelUser

-(NSString*) description {
    return [NSString stringWithFormat:@"NINChannelUser userID: %@, displayName: %@, iconURL: %@", self.userID, self.displayName, self.iconURL];
}

+(NINChannelUser*) userWithID:(NSString*)userID realName:(NSString*)realName displayName:(NSString*)displayName  iconURL:(NSString*)iconURL guest:(BOOL)guest {
    NINChannelUser* user = [NINChannelUser new];

    NSCAssert(userID.length > 0, @"Invalid user id!");

    user.userID = userID;
    user.realName = realName;
    user.displayName = displayName;
    user.iconURL = iconURL;
    user.guest = guest;

    return user;
}

@end
