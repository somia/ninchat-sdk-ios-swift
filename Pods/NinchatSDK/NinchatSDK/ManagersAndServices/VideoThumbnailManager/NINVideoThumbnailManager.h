//
//  NINVideoThumbnailManager.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 01/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef void (^extractThumbnailCallback)(NSError* _Nullable error, BOOL fromCache, UIImage* _Nullable thumbnail);

@interface NINVideoThumbnailManager : NSObject

-(void) getVideoThumbnail:(NSString*)videoURL completion:(extractThumbnailCallback)completion;

@end

NS_ASSUME_NONNULL_END
