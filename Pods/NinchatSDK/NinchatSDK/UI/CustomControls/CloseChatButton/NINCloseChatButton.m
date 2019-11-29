//
//  NINCloseChatButton.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 13/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINCloseChatButton.h"
#import "NINUtils.h"
#import "NINChatSession.h"
#import "NINChatSession+Internal.h"

@interface NINCloseChatButton ()

@property (nonatomic, strong) IBOutlet UIButton* theButton;
@property (nonatomic, strong) IBOutlet UILabel* buttonTitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView* closeButtonImageView;

@end

@implementation NINCloseChatButton

#pragma mark - Public methods

-(void) setButtonTitle:(NSString*)title {
    self.buttonTitleLabel.text = title;
}

-(void) overrideAssetsWithSession:(NINChatSession*)session {
    UIImage* overrideImage = [session overrideImageAssetForKey:NINImageAssetKeyChatCloseButton];

    if (overrideImage != nil) {
        // Overriding (setting) the button background image; no border.
        [self.theButton setBackgroundImage:overrideImage forState:UIControlStateNormal];
        self.backgroundColor = [UIColor clearColor];
        self.theButton.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 0;
        self.layer.borderWidth = 0;
    }

    // Handle overriding the button icon image
    self.closeButtonImageView.hidden = NO;
    UIImage* icon = [session overrideImageAssetForKey:NINImageAssetKeyIconChatCloseButton];
    if (icon != nil) {
        self.closeButtonImageView.image = icon;
    }

    // Handle overriding the button text & border color
    UIColor* textColor = [session overrideColorAssetForKey:NINColorAssetKeyButtonSecondaryText];
    if (textColor != nil) {
        self.buttonTitleLabel.textColor = textColor;
        self.layer.borderColor = textColor.CGColor;
        self.closeButtonImageView.tintColor = textColor;
    }
}

#pragma mark - IBAction handlers

-(IBAction) pressed:(UIButton*)button {
    self.pressedCallback();
}

-(void) awakeFromNib {
    [super awakeFromNib];

    // Only do this if the corner radius has not been set yet
    if (self.layer.cornerRadius < 0.1) {
        // Add rounded corners and a border
        self.layer.cornerRadius = self.bounds.size.height / 2;
        self.layer.masksToBounds = YES;
        self.layer.borderColor = [UIColor colorWithRed:0 green:138/255.0 blue:1 alpha:1].CGColor;
        self.layer.borderWidth = 1;
    }

    // Workaround for https://openradar.appspot.com/18448072
    UIImage* image = self.closeButtonImageView.image;
    self.closeButtonImageView.image = nil;
    self.closeButtonImageView.image = image;
}

@end

#pragma mark - NINEmbeddableCloseChatButton

@implementation NINEmbeddableCloseChatButton

// Loads the NINNavigationBar view from its xib
-(NINCloseChatButton*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:@"NINCloseChatButton" owner:nil options:nil];

    NSCAssert([objects[0] isKindOfClass:[NINCloseChatButton class]], @"Invalid class resource");

    return (NINCloseChatButton*)objects[0];
}

// Substitutes the original view content (eg. from Storyboard) with contents of the xib
-(id) awakeAfterUsingCoder:(NSCoder *)aDecoder {
    NINCloseChatButton* newView = [self loadViewFromNib];

    newView.frame = self.frame;
    newView.autoresizingMask = self.autoresizingMask;
    newView.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints;

    newView.pressedCallback = self.pressedCallback;

    // Not to break the layout surrounding this view, we must copy the constraints over
    // to the newly loaded view
    for (NSLayoutConstraint* constraint in self.constraints) {
        id firstItem = (constraint.firstItem == self) ? newView : constraint.firstItem;
        id secondItem = (constraint.secondItem == self) ? newView : constraint.secondItem;

        [newView addConstraint:[NSLayoutConstraint constraintWithItem:firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
    }

    return newView;
}

@end
