//
//  NINToast.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINToast.h"
#import "NINUtils.h"
#import "NINTouchView.h"

@interface NINToast ()

@property (nonatomic, strong) IBOutlet UIView* containerView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topInsetHeightConstraint;
@property (nonatomic, strong) IBOutlet UILabel* messageLabel;

@property (nonatomic, copy) emptyBlock touchedCallback;
@property (nonatomic, strong) NINTouchView* touchView;

@end

static const NSTimeInterval kAnimationDuration = 0.3;
static const NSTimeInterval kToastDuration = 1.5;
static const CGFloat kHiddenAlpha = 0.6;

@implementation NINToast

+(void) showWithMessage:(NSString*)message bgColorOverride:(UIColor*)color touchedCallback:(emptyBlock)touchedCallback callback:(emptyBlock)callback {
    NSCAssert(UIApplication.sharedApplication.keyWindow != nil, @"No key window");

    NINToast* toast = (NINToast*)loadFromNib(NINToast.class);
    toast.translatesAutoresizingMaskIntoConstraints = NO;

    toast.messageLabel.text = message;
    toast.touchedCallback = touchedCallback;

    if (color != nil) {
        toast.containerView.backgroundColor = color;
    }

    UIView* window = UIApplication.sharedApplication.keyWindow;
    [window addSubview:toast];

    if (@available(iOS 11.0, *)) {
        // Add filler space on top of toast to match the safe area inset
        toast.topInsetHeightConstraint.constant = window.safeAreaInsets.top;
    }

    NSArray* constraints = @[ constrain(toast, window, NSLayoutAttributeLeft),
                              constrain(toast, window, NSLayoutAttributeTop),
                              constrain(toast, window, NSLayoutAttributeRight) ];
    [NSLayoutConstraint activateConstraints:constraints];

    CGFloat toastBottom = toast.frame.origin.y + toast.bounds.size.height;
    CGAffineTransform hiddenTransform = CGAffineTransformMakeTranslation(0, -toastBottom);

    toast.transform = hiddenTransform;
    toast.alpha = kHiddenAlpha;

    // Add a transparent view to cover the area where the toast will appear; use
    // this view to receive tap gestures.
    toast.touchView = [NINTouchView new];
    toast.touchView.translatesAutoresizingMaskIntoConstraints = NO;
    toast.touchView.exclusiveTouch = YES;
    [window addSubview:toast.touchView];
    NSArray* touchViewConstraints = @[ constrain(toast.touchView, window, NSLayoutAttributeLeft),
                                       constrain(toast.touchView, window, NSLayoutAttributeTop),
                                       constrain(toast.touchView, window, NSLayoutAttributeRight),
                                       [toast.touchView.heightAnchor constraintEqualToConstant:toast.bounds.size.height]
                                       ];
    [NSLayoutConstraint activateConstraints:touchViewConstraints];
    __weak typeof(toast) weakToast = toast;
    toast.touchView.touchCallback = ^{
        if (weakToast.touchedCallback != nil) {
            weakToast.touchedCallback();
        }
    };

    // Animate the toast into view
    [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        toast.transform = CGAffineTransformIdentity;
        toast.alpha = 1.0;
    } completion:^(BOOL finished) {
        // After a delay, animate the toast out of sight again
        [UIView animateWithDuration:kAnimationDuration delay:kToastDuration options:UIViewAnimationOptionAllowUserInteraction animations:^{
            toast.transform = hiddenTransform;
            toast.alpha = kHiddenAlpha;
        } completion:^(BOOL finished) {
            [toast.touchView removeFromSuperview];
            [toast removeFromSuperview];
            if (callback != nil) {
                callback();
            }
        }];
    }];
}

+(void) showWithErrorMessage:(NSString*)message touchedCallback:(emptyBlock)touchedCallback callback:(emptyBlock)callback {
    [NINToast showWithMessage:message bgColorOverride:nil touchedCallback:touchedCallback callback:callback];
}

+(void) showWithErrorMessage:(NSString*)message callback:(emptyBlock)callback {
    [NINToast showWithErrorMessage:message touchedCallback:nil callback:callback];
}

+(void) showWithInfoMessage:(NSString*)message callback:(emptyBlock)callback {
    [NINToast showWithMessage:message bgColorOverride:[UIColor colorWithRed:0 green:138/255.0 blue:1 alpha:1] touchedCallback:nil callback:callback];
}

@end
