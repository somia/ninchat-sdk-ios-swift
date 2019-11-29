//
//  NINAvatarConfig.m
//  AFNetworking
//
//  Created by Matti Dahlbom on 29/11/2018.
//

#import "NINAvatarConfig.h"

@interface NINAvatarConfig ()

// Writeable overrides
@property (nonatomic, assign) BOOL show;
@property (nonatomic, strong) NSString* imageOverrideUrl;
@property (nonatomic, strong) NSString* nameOverride;

@end

@implementation NINAvatarConfig

+(instancetype) configWithAvatar:(id)avatar name:(NSString*)name {
    NINAvatarConfig* cfg = [NINAvatarConfig new];

    cfg.show = YES;

    if (avatar != nil) {
        if ([avatar isKindOfClass:NSString.class]) {
            // If it is a string, interpret that to be an image override URL
            cfg.imageOverrideUrl = (NSString*)avatar;
        } else if ([avatar isKindOfClass:NSNumber.class]) {
            // If it is a bool however, use that value as the show -value
            cfg.show = [((NSNumber*)avatar) boolValue];
        }
    }

    if (name.length > 0) {
        cfg.nameOverride = name;
    }

    return cfg;
}

@end
