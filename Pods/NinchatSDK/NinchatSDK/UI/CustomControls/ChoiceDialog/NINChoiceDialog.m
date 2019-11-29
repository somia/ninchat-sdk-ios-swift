//
//  NINChoiceDialog.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 04/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChoiceDialog.h"
#import "NINChoiceDialogRow.h"
#import "NINUtils.h"
#import "NINTouchView.h"

static const NSTimeInterval kAnimationDuration = 0.3;
static const CGFloat kHiddenAlpha = 0.6;

@interface NINChoiceDialog ()

@property (nonatomic, strong) IBOutlet UIStackView* stackView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* bottomInsetHeightConstraint;

@property (nonatomic, assign) CGAffineTransform hiddenTransform;
@property (nonatomic, strong) NINTouchView* touchView;

@end

@implementation NINChoiceDialog

-(void) dismissWithCompletion:(emptyBlock)completion {
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.transform = self.hiddenTransform;
        self.alpha = kHiddenAlpha;
        self.touchView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.touchView removeFromSuperview];
        completion();
    }];
}

+(NINChoiceDialog*) showWithOptionTitles:(NSArray<NSString*>*)optionTitles completion:(choiceDialogCompletionCallback)completion {
    NINChoiceDialog* dialog = (NINChoiceDialog*)loadFromNib(NINChoiceDialog.class);
    dialog.translatesAutoresizingMaskIntoConstraints = NO;

    // Create a 'touch view' to block the background and to receive touches
    __weak typeof(dialog) weakDialog = dialog;
    dialog.touchView = [NINTouchView new];
    dialog.touchView.translatesAutoresizingMaskIntoConstraints = NO;

    dialog.touchView.touchCallback = ^{
        [weakDialog dismissWithCompletion:^{
            completion(YES, 0);
        }];
    };
    dialog.touchView.backgroundColor = [UIColor blackColor];

    UIView* window = UIApplication.sharedApplication.keyWindow;
    [window addSubview:dialog.touchView];
    [window addSubview:dialog];

    NSArray* touchViewConstraints = @[ constrain(dialog.touchView, window, NSLayoutAttributeLeft),
                                       constrain(dialog.touchView, window, NSLayoutAttributeBottom),
                                       constrain(dialog.touchView, window, NSLayoutAttributeRight),
                                       constrain(dialog.touchView, window, NSLayoutAttributeTop) ];
    [NSLayoutConstraint activateConstraints:touchViewConstraints];

    if (@available(iOS 11.0, *)) {
        // Add filler space on top of toast to match the safe area inset
        dialog.bottomInsetHeightConstraint.constant = window.safeAreaInsets.bottom;
    }

    // Constrain the view to match the screen bottom
    NSArray* constraints = @[ constrain(dialog, window, NSLayoutAttributeLeft),
                              constrain(dialog, window, NSLayoutAttributeBottom),
                              constrain(dialog, window, NSLayoutAttributeRight) ];
    [NSLayoutConstraint activateConstraints:constraints];

    dialog.hiddenTransform = CGAffineTransformMakeTranslation(0, dialog.bounds.size.height);

    dialog.transform = dialog.hiddenTransform;
    dialog.alpha = kHiddenAlpha;
    dialog.touchView.alpha = 0;

    // Animate the dialog into view
    [UIView animateWithDuration:kAnimationDuration animations:^{
        dialog.transform = CGAffineTransformIdentity;
        dialog.alpha = 1.0;
        dialog.touchView.alpha = 0.4;
    } completion:nil];

    for (NSInteger i = 0; i < optionTitles.count; i++) {
        NINChoiceDialogRow* row = [NINChoiceDialogRow rowWithTitle:optionTitles[i] pressedCallback:^{
            [weakDialog dismissWithCompletion:^{
                completion(NO, i);
            }];
        }];
        [weakDialog.stackView addArrangedSubview:row];
    }

    return dialog;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
