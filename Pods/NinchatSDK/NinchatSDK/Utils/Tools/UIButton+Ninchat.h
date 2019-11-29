//
//  UIButton+Ninchat.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 03/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"
#import "NINChatSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (Ninchat)

+(instancetype) buttonWithPressedCallback:(emptyBlock)callback;

-(void) overrideAssetsWithSession:(NINChatSession*)session isPrimaryButton:(BOOL)primary;

@end

NS_ASSUME_NONNULL_END
