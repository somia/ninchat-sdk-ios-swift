//
//  NINVideoCallConsentDialog.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import AFNetworking;

#import "NINVideoCallConsentDialog.h"
#import "NINUtils.h"
#import "NINChannelUser.h"
#import "NINChatSession+Internal.h"
#import "NINSessionManager.h"
#import "UIButton+Ninchat.h"
#import "NINPermissions.h"
#import "NINToast.h"
#import "NINAvatarConfig.h"

// UI texts
static NSString* const kAcceptText = @"Accept";
static NSString* const kDeclineText = @"Decline";

@interface NINVideoCallConsentDialog ()

@property (nonatomic, strong) IBOutlet UIView* headerContainerView;
@property (nonatomic, strong) IBOutlet UIView* bottomContainerView;
@property (nonatomic, strong) IBOutlet UILabel* titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView* avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel* usernameLabel;
@property (nonatomic, strong) IBOutlet UILabel* infoLabel;
@property (nonatomic, strong) IBOutlet UIButton* acceptButton;
@property (nonatomic, strong) IBOutlet UIButton* rejectButton;

@property (nonatomic, copy) consentDialogClosedBlock closedBlock;
@property (nonatomic, strong) UIView* faderView;

@end

static const NSTimeInterval kAnimationDuration = 0.3;

@implementation NINVideoCallConsentDialog

#pragma mark - Private methods

-(void) closeWithResult:(NINConsentDialogResult)result {
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.transform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height);
        self.faderView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.faderView removeFromSuperview];
        [self removeFromSuperview];

        self.closedBlock(result);
    }];
}

-(void) applyAssetOverrides:(NINChatSession*)session {
    [self.acceptButton overrideAssetsWithSession:session isPrimaryButton:YES];
    [self.rejectButton overrideAssetsWithSession:session isPrimaryButton:NO];

    UIColor* backgroundColor = [session overrideColorAssetForKey:NINColorAssetKeyModalBackground];
    if (backgroundColor != nil) {
        self.headerContainerView.backgroundColor = backgroundColor;
        self.bottomContainerView.backgroundColor = backgroundColor;
    }

    UIColor* textColor = [session overrideColorAssetForKey:NINColorAssetKeyModalText];
    if (textColor != nil) {
        self.titleLabel.textColor = textColor;
        self.usernameLabel.textColor = textColor;
        self.infoLabel.textColor = textColor;
    }
}

+(NINVideoCallConsentDialog*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:@"NINVideoCallConsentDialog" owner:nil options:nil];

    NSCAssert([objects[0] isKindOfClass:[NINVideoCallConsentDialog class]], @"Invalid class resource");

    return (NINVideoCallConsentDialog*)objects[0];
}

#pragma mark - Public methods

+(instancetype) showOnView:(UIView*)view forRemoteUser:(NINChannelUser*)user sessionManager:(NINSessionManager*)sessionManager closedBlock:(consentDialogClosedBlock)closedBlock {
    NINVideoCallConsentDialog* d = [NINVideoCallConsentDialog loadViewFromNib];
    d.translatesAutoresizingMaskIntoConstraints = NO;
    d.closedBlock = closedBlock;

    NINAvatarConfig* agentAvatarConfig = [NINAvatarConfig configWithAvatar:[sessionManager.siteConfiguration valueForKey:@"agentAvatar"] name:[sessionManager.siteConfiguration valueForKey:@"agentName"]];

    // Caller's Avatar image
    if (agentAvatarConfig.imageOverrideUrl != nil) {
        [d.avatarImageView setImageWithURL:[NSURL URLWithString:agentAvatarConfig.imageOverrideUrl]];
    } else {
        [d.avatarImageView setImageWithURL:[NSURL URLWithString:user.iconURL]];
    }

    // Caller's name
    if (agentAvatarConfig.nameOverride != nil) {
        d.usernameLabel.text = agentAvatarConfig.nameOverride;
    } else {
        d.usernameLabel.text = user.displayName;
    }

    [d applyAssetOverrides:sessionManager.ninchatSession];

    // Set translated UI texts
    [d.acceptButton setTitle:[sessionManager translation:kAcceptText formatParams:nil] forState:UIControlStateNormal];
    [d.rejectButton setTitle:[sessionManager translation:kDeclineText formatParams:nil] forState:UIControlStateNormal];

    // Create a "fader" view to fade out the background a bit and constrain it to match the view
    d.faderView = [[UIView alloc] initWithFrame:view.bounds];
    d.faderView.translatesAutoresizingMaskIntoConstraints = NO;
    d.faderView.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    d.faderView.alpha = 0.0;
    NSArray* faderConstraints = @[
                                  constrain(d.faderView, view, NSLayoutAttributeTop),
                                  constrain(d.faderView, view, NSLayoutAttributeRight),
                                  constrain(d.faderView, view, NSLayoutAttributeBottom),
                                  constrain(d.faderView, view, NSLayoutAttributeLeft)
                                  ];
    [view addSubview:d.faderView];
    [NSLayoutConstraint activateConstraints:faderConstraints];

    // Constrain the view to the given view's top edge
    NSArray* constraints = @[
                             constrain(d, view, NSLayoutAttributeTop),
                             constrain(d, view, NSLayoutAttributeRight),
                             constrain(d, view, NSLayoutAttributeLeft)
                             ];
    [view addSubview:d];
    [NSLayoutConstraint activateConstraints:constraints];

    // Animate us in
    d.transform = CGAffineTransformMakeTranslation(0, -d.bounds.size.height);
    [UIView animateWithDuration:kAnimationDuration animations:^{
        d.transform = CGAffineTransformIdentity;
        d.faderView.alpha = 0.6;
    } completion:^(BOOL finished) {

    }];

    // UI texts
    d.titleLabel.text = [sessionManager translation:@"You are invited to a video chat" formatParams:nil];
    d.infoLabel.text = [sessionManager translation:@"wants to video chat with you" formatParams:nil];

    return d;
}

#pragma mark - IBAction handlers

-(IBAction) acceptButtonPressed:(UIButton*)button {
    // Check microphone permissions
    checkMicrophonePermission(^(NSError* error) {
        if (error != nil) {
            NSLog(@"Microphone permission denied: %@", error);
            [NINToast showWithErrorMessage:@"Microphone access denied." touchedCallback:^{
                NSLog(@"Showing app settings");
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            } callback:nil];
            [self closeWithResult:NINConsentDialogResultRejected];
        } else {
            // Check camera permissions
            NSLog(@"Microphone permission OK.");
            checkVideoPermission(^(NSError* error) {
                if (error != nil) {
                    NSLog(@"Video (camera) permission denied: %@", error);
                    [NINToast showWithErrorMessage:@"Camera access denied." touchedCallback:^{
                        NSLog(@"Showing app settings");
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    } callback:nil];
                    [self closeWithResult:NINConsentDialogResultRejected];
                } else {
                    // Permissions ok, can accept this call!
                    NSLog(@"Camera permission OK.");
                    [self closeWithResult:NINConsentDialogResultAccepted];
                }
            });
        }
    });
}

-(IBAction) rejectButtonPressed:(UIButton*)button {
    [self closeWithResult:NINConsentDialogResultRejected];
}

#pragma mark - Lifecycle etc.

-(void) awakeFromNib {
    [super awakeFromNib];

    // Make things round
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
    self.acceptButton.layer.cornerRadius = self.acceptButton.bounds.size.height / 2;
    self.rejectButton.layer.cornerRadius = self.rejectButton.bounds.size.height / 2;
    self.rejectButton.layer.borderWidth = 1;
    self.rejectButton.layer.borderColor = [UIColor colorWithRed:0 green:138/255.0 blue:255/255.0 alpha:1].CGColor;

    // Workaround for https://openradar.appspot.com/18448072
    UIImage* image = self.avatarImageView.image;
    self.avatarImageView.image = nil;
    self.avatarImageView.image = image;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
