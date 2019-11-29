//
//  UIButton+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 03/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <objc/runtime.h>

#import "UIButton+Ninchat.h"
#import "NINChatSession+Internal.h"

static char kAssociatedObjectKey;

#pragma mark - CallbackHandler

@interface CallbackHandler : NSObject

@property (nonatomic, strong) emptyBlock callback;

@end

@implementation CallbackHandler

+(instancetype) handlerWithCallback:(emptyBlock)callback {
    CallbackHandler* handler = [CallbackHandler new];
    handler.callback = callback;

    return handler;
}

-(void) pressed {
    self.callback();
}

@end

@implementation UIButton (Ninchat)

#pragma mark - Public methods

+(instancetype) buttonWithPressedCallback:(emptyBlock)callback {
    UIButton* button = [UIButton new];
    CallbackHandler* handler = [CallbackHandler handlerWithCallback:callback];
    objc_setAssociatedObject(button, &kAssociatedObjectKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [button addTarget:handler action:@selector(pressed) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

-(void) overrideAssetsWithSession:(NINChatSession*)session isPrimaryButton:(BOOL)primary {
    UIImage* overrideImage = [session overrideImageAssetForKey:(primary ? NINImageAssetKeyPrimaryButton : NINImageAssetKeySecondaryButton)];

    if (overrideImage != nil) {
        [self setBackgroundImage:overrideImage forState:UIControlStateNormal];
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 0;
        self.layer.borderWidth = 0;
    } else {
        NINColorAssetKey key = primary ? NINColorAssetKeyButtonPrimaryText : NINColorAssetKeyButtonSecondaryText;
        UIColor* titleColor = [session overrideColorAssetForKey:key];
        if (titleColor != nil) {
            [self setTitleColor:titleColor forState:UIControlStateNormal];
        }
    }
}

@end
