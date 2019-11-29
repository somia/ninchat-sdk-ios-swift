//
//  NINAvatarConfig.h
//  AFNetworking
//
//  Created by Matti Dahlbom on 29/11/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NINAvatarConfig : NSObject

/** Whether or not to show the avatar. */
@property (nonatomic, assign, readonly) BOOL show;

/** Avatar image override URL. nil for no override. */
@property (nonatomic, strong, readonly) NSString* imageOverrideUrl;

/** Name override. nil for no override. */
@property (nonatomic, strong, readonly) NSString* nameOverride;

+(instancetype) configWithAvatar:(id)avatar name:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
