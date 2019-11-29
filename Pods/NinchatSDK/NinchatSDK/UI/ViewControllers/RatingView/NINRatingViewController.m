//
//  NINRatingViewController.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 13/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINRatingViewController.h"
#import "NINSessionManager.h"
#import "UITextView+Ninchat.h"
#import "NINUtils.h"


// UI strings
static NSString* const kTitleText = @"How was our customer service?";
static NSString* const kSkipText = @"Skip";

@interface NINRatingViewController ()

@property (nonatomic, strong) IBOutlet UIView* topContainerView;
@property (nonatomic, strong) IBOutlet UITextView* titleTextView;
@property (nonatomic, strong) IBOutlet UIButton* positiveButton;
@property (nonatomic, strong) IBOutlet UIButton* neutralButton;
@property (nonatomic, strong) IBOutlet UIButton* negativeButton;
@property (nonatomic, strong) IBOutlet UILabel* positiveLabel;
@property (nonatomic, strong) IBOutlet UILabel* neutralLabel;
@property (nonatomic, strong) IBOutlet UILabel* negativeLabel;
@property (nonatomic, strong) IBOutlet UIButton* skipButton;

@end

@implementation NINRatingViewController

#pragma mark - Private methods

-(void) applyAssetOverrides {
    UIColor* topBackgroundColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetBackgroundTop];
    if (topBackgroundColor != nil) {
        self.topContainerView.backgroundColor = topBackgroundColor;
    }

    UIColor* bottomBackgroundColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetBackgroundBottom];
    if (bottomBackgroundColor != nil) {
        self.view.backgroundColor = bottomBackgroundColor;
    }

    UIColor* textTopColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetTextTop];
    if (textTopColor != nil) {
        self.titleTextView.textColor = textTopColor;
    }

    UIImage* positiveIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconRatingPositive];
    if (positiveIcon != nil) {
        [self.positiveButton setImage:positiveIcon forState:UIControlStateNormal];
    }

    UIImage* neutralIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconRatingNeutral];
    if (neutralIcon != nil) {
        [self.neutralButton setImage:neutralIcon forState:UIControlStateNormal];
    }

    UIImage* negativeIcon = [self.sessionManager.ninchatSession overrideImageAssetForKey:NINImageAssetKeyIconRatingNegative];
    if (negativeIcon != nil) {
        [self.negativeButton setImage:negativeIcon forState:UIControlStateNormal];
    }

    UIColor* positiveColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetRatingPositiveText];
    if (positiveColor != nil) {
        self.positiveLabel.textColor = positiveColor;
    }

    UIColor* neutralColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetRatingNeutralText];
    if (neutralColor != nil) {
        self.neutralLabel.textColor = neutralColor;
    }

    UIColor* negativeColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetRatingNegativeText];
    if (negativeColor != nil) {
        self.negativeLabel.textColor = negativeColor;
    }

    UIColor* linkColor = [self.sessionManager.ninchatSession overrideColorAssetForKey:NINColorAssetLink];
    if (linkColor != nil) {
        self.titleTextView.linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
        [self.skipButton setTitleColor:linkColor forState:UIControlStateNormal];
    }
}

#pragma mark - IBAction handlers

-(IBAction) happyFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Happy face pressed");

    [self.sessionManager finishChat:@(kNINChatRatingHappy)];
}

-(IBAction) neutralFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Neutral face pressed");

    [self.sessionManager finishChat:@(kNINChatRatingNeutral)];
}

-(IBAction) sadFaceButtonPressed:(UIButton*)sender {
    NSLog(@"Sad face pressed");

    [self.sessionManager finishChat:@(kNINChatRatingSad)];
}

-(IBAction) skipButtonPressed:(id)sender {
    NSLog(@"Skip button pressed");

    [self.sessionManager finishChat:nil];
}

#pragma mark - From UIViewController

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Lifecycle, etc

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        // Presenting a view controller will trigger a re-evaluation of
        // supportedInterfaceOrientations: and thus will force this view controller into portrait
        static dispatch_once_t presentVcOnceToken;
        dispatch_once(&presentVcOnceToken, ^{
            runOnMainThreadWithDelay(^{
                UIViewController* vc = [UIViewController new];
                [self presentViewController:vc animated:NO completion:nil];
                [self dismissViewControllerAnimated:NO completion:nil];
            }, 0.1);
        });
    }
}

-(void) viewDidLoad {
    [super viewDidLoad];

    // Translations
    [self.titleTextView setFormattedText:[self.sessionManager translation:kTitleText formatParams:nil]];
    [self.skipButton setTitle:[self.sessionManager translation:kSkipText formatParams:nil] forState:UIControlStateNormal];

    // UI texts
    self.positiveLabel.text = [self.sessionManager translation:@"Good" formatParams:nil];
    self.neutralLabel.text = [self.sessionManager translation:@"Okay" formatParams:nil];
    self.negativeLabel.text =  [self.sessionManager translation:@"Poor" formatParams:nil];

    // Apply asset overrides
    [self applyAssetOverrides];
}

@end
