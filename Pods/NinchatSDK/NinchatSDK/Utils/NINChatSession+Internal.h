//
//  NINSessionManager+Internal.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatSession.h"

@interface NINChatSession (Internal)

/** Outputs SDK log entry if the delegate is set and defines the log method. */
-(void) sdklog:(NSString*_Nonnull)format, ...;

/** Wraps the delegate call to overrideImageAssetForKey. */
-(UIImage* _Nullable) overrideImageAssetForKey:(NINImageAssetKey _Nonnull)assetKey;

/** Wraps the delegate call to overrideColorAssetForKey. */
-(UIColor* _Nullable) overrideColorAssetForKey:(NINColorAssetKey _Nonnull)assetKey;

@end
