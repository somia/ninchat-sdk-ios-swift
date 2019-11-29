//
//  NINBaseViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 10/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINBaseViewController.h"
#import "NINSessionManager.h"
#import "NINNavigationBar.h"

@interface NINBaseViewController () 

@end

@implementation NINBaseViewController

#pragma mark - Private methods

-(void) keyboardWillShow:(NSNotification*)notification {
    CGRect beginRect = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    if (CGRectEqualToRect(beginRect, endRect)) {
        // Keyboard already visible - take no action.
        return;
    }

    CGSize keyboardSize = endRect.size;
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    CGFloat amountToRaiseView = keyboardSize.height;

    if (@available(iOS 11.0, *)) {
        // Remove any safe area from the amount to raise the view - this will make the
        // keyboard top edge match the previous safe area bottom.
        amountToRaiseView -= self.view.safeAreaInsets.bottom;
    }

    [UIView animateWithDuration:animationDuration animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, -amountToRaiseView);
    } completion:^(BOOL finished) {

    }];
}

-(void) keyboardWillHide:(NSNotification*)notification {
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:animationDuration animations:^{
        self.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - From UINavigationControllerDelegate

-(UIInterfaceOrientationMask) navigationControllerSupportedInterfaceOrientations:(UINavigationController*)navigationController {
    return navigationController.topViewController.supportedInterfaceOrientations;
}

#pragma mark - From UITextViewDelegate

// Pre-iOS 10
-(BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    return YES;
}

// iOS 10 and up
-(BOOL) textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0)) {
    return YES;
}

#pragma mark - Lifecycle etc.

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Make sure we have a navigation controller
    NSCAssert(self.navigationController != nil, @"Must have a navigation controller");

    self.navigationController.delegate = self;
}

-(void) viewDidLoad {
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;
    self.customNavigationBar.closeButtonPressedCallback = ^{
        [weakSelf.sessionManager closeChat];
    };
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
