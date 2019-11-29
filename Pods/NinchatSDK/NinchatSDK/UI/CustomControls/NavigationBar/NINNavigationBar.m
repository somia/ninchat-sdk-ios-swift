//
//  NINNavigationBar.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 10/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINNavigationBar.h"
#import "NINUtils.h"

@implementation NINNavigationBar

#pragma mark - Private methods



#pragma mark - IBAction handlers

-(IBAction) closeButtonPressed:(UIButton*)sender {
    NSLog(@"Close button pressed.");
    if (self.closeButtonPressedCallback != nil) {
        self.closeButtonPressedCallback();
    }
}

#pragma mark - Lifecycle, etc.

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end

#pragma mark - NINEmbeddableNavigationBar

@implementation NINEmbeddableNavigationBar

// Loads the NINNavigationBar view from its xib
-(NINNavigationBar*) loadViewFromNib {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:@"NINNavigationBar" owner:nil options:nil];

    return (NINNavigationBar*)objects[0];
}

// Substitutes the original view content (eg. from Storyboard) with contents of the xib
-(id) awakeAfterUsingCoder:(NSCoder *)aDecoder {
    UIView* newView = [self loadViewFromNib];

    newView.frame = self.frame;
    newView.autoresizingMask = self.autoresizingMask;
    newView.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints;
    newView.clipsToBounds = self.clipsToBounds;

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
