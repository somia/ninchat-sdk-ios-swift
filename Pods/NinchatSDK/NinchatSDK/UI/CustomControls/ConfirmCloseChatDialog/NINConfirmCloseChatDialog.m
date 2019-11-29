//
//  NINConfirmCloseChatDialog.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/11/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINConfirmCloseChatDialog.h"
#import "NINChatSession.h"
#import "NINChatSession+Internal.h"
#import "NINSessionManager.h"
#import "UIButton+Ninchat.h"
#import "NINUtils.h"
#import "UITextView+Ninchat.h"

@interface NINConfirmCloseChatDialog ()

@property (nonatomic, strong) IBOutlet UIView* headerContainerView;
@property (nonatomic, strong) IBOutlet UIView* bottomContainerView;
@property (nonatomic, strong) IBOutlet UILabel* titleLabel;
@property (nonatomic, strong) IBOutlet UITextView* infoTextView;
@property (nonatomic, strong) IBOutlet UIButton* closeButton;
@property (nonatomic, strong) IBOutlet UIButton* cancelButton;

@property (nonatomic, copy) confirmCloseChatDialogClosedBlock closedBlock;
@property (nonatomic, strong) UIView* faderView;

@end

static const NSTimeInterval kAnimationDuration = 0.3;

@implementation NINConfirmCloseChatDialog

#pragma mark - Private methods

-(void) closeWithResult:(NINConfirmCloseChatDialogResult)result {
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.transform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height);
        self.faderView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.faderView removeFromSuperview];
        [self removeFromSuperview];

        self.closedBlock(result);
    }];
}

-(void) faderViewTapped:(UIGestureRecognizer*)recognizer {
    [self closeWithResult:NINConfirmCloseChatDialogResultCancel];
}

-(void) applyAssetOverrides:(NINChatSession*)session {
    [self.closeButton overrideAssetsWithSession:session isPrimaryButton:YES];
    [self.cancelButton overrideAssetsWithSession:session isPrimaryButton:NO];

    UIColor* backgroundColor = [session overrideColorAssetForKey:NINColorAssetKeyModalBackground];
    if (backgroundColor != nil) {
        self.headerContainerView.backgroundColor = backgroundColor;
        self.bottomContainerView.backgroundColor = backgroundColor;
    }

    UIColor* textColor = [session overrideColorAssetForKey:NINColorAssetKeyModalText];
    if (textColor != nil) {
        self.titleLabel.textColor = textColor;
        self.infoTextView.textColor = textColor;
    }
}

+(NINConfirmCloseChatDialog*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:@"NINConfirmCloseChatDialog" owner:nil options:nil];

    NSCAssert([objects[0] isKindOfClass:[NINConfirmCloseChatDialog class]], @"Invalid class resource");

    return (NINConfirmCloseChatDialog*)objects[0];
}

#pragma mark - Public methods

+(instancetype) showOnView:(UIView*)view sessionManager:(NINSessionManager*)sessionManager closedBlock:(confirmCloseChatDialogClosedBlock)closedBlock {
    NINConfirmCloseChatDialog* d = [NINConfirmCloseChatDialog loadViewFromNib];
    d.translatesAutoresizingMaskIntoConstraints = NO;
    d.closedBlock = closedBlock;

    [d applyAssetOverrides:sessionManager.ninchatSession];

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

    // Install a tap recognizer on the fader view. Tapping it will cancel this dialog.
    // TODO disabled because for some reason this seems to read touches on the dialog instead of the fader and block the close button from being usable
//    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:d action:@selector(faderViewTapped:)];
//    [d.faderView addGestureRecognizer:tapRecognizer];

    // Constrain the view to the given view's top edge
    NSArray* constraints = @[
                             constrain(d, view, NSLayoutAttributeTop),
                             constrain(d, view, NSLayoutAttributeRight),
                             constrain(d, view, NSLayoutAttributeLeft)
                             ];
    [view addSubview:d];
    [NSLayoutConstraint activateConstraints:constraints];

    // UI texts
    NSString* confirmText = [sessionManager.siteConfiguration valueForKey:@"closeConfirmText"];
    if (confirmText != nil) {
        [d.infoTextView setFormattedText:confirmText];
    }
    
    NSString* closeChatText = [sessionManager translation:@"Close chat" formatParams:nil];
    d.titleLabel.text = closeChatText;
    [d.closeButton setTitle:closeChatText forState:UIControlStateNormal];
    [d.cancelButton setTitle:[sessionManager translation:@"Continue chat" formatParams:nil] forState:UIControlStateNormal];

    // Animate us in
    d.transform = CGAffineTransformMakeTranslation(0, -d.bounds.size.height);
    [UIView animateWithDuration:kAnimationDuration animations:^{
        d.transform = CGAffineTransformIdentity;
        d.faderView.alpha = 0.6;
    } completion:^(BOOL finished) {

    }];

    return d;
}

#pragma mark - IBAction handlers

-(IBAction) closeButtonPressed:(UIButton*)button {
    [self closeWithResult:NINConfirmCloseChatDialogResultClose];
}

-(IBAction) cancelButtonPressed:(UIButton*)button {
    [self closeWithResult:NINConfirmCloseChatDialogResultCancel];
}

#pragma mark - Lifecycle etc.

-(void) awakeFromNib {
    [super awakeFromNib];

    // Make things round
    self.closeButton.layer.cornerRadius = self.closeButton.bounds.size.height / 2;
    self.cancelButton.layer.cornerRadius = self.cancelButton.bounds.size.height / 2;
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.borderColor = [UIColor colorWithRed:0 green:138/255.0 blue:255/255.0 alpha:1].CGColor;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}
@end
