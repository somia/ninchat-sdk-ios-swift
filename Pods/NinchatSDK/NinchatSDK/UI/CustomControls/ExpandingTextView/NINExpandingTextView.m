//
//  NINExpandingTextView.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 04/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINExpandingTextView.h"

@interface NINExpandingTextView () <UITextViewDelegate>

@property (nonatomic, strong) NSLayoutConstraint* heightConstraint;

@property (nonatomic, strong) id changeObserver;
@property (nonatomic, strong) id endEditingObserver;

@end

@implementation NINExpandingTextView

#pragma mark - Private methods

-(void) updateSize {
    CGSize fittingSize = [self sizeThatFits:CGSizeMake(self.bounds.size.width, 9999)];
    CGFloat newHeight = ceil(fittingSize.height);

    if ((_maximumHeight > 0) && (newHeight > _maximumHeight)) {
        // Limiting the max size; enable scrolling.
        self.scrollEnabled = YES;
        return;
    }

    self.scrollEnabled = YES;

    if (newHeight != self.heightConstraint.constant) {
        self.heightConstraint.constant = newHeight;
        [self.superview setNeedsLayout];
    }
}

-(void) commonInit {
    self.scrollEnabled = NO;
    self.scrollsToTop = NO;

    // Find our height constraint; it must exist!
    for (NSLayoutConstraint* constraint in self.constraints) {
        if ((constraint.firstItem == self) && (constraint.firstAttribute == NSLayoutAttributeHeight)) {
            self.heightConstraint = constraint;
            break;
        }
    }
    NSCAssert(self.heightConstraint != nil, @"Height constraint must have been set in IB!");

    __weak typeof(self) weakSelf = self;
    self.changeObserver = [NSNotificationCenter.defaultCenter addObserverForName:UITextViewTextDidChangeNotification object:self queue:nil usingBlock:^(NSNotification* note) {
        [weakSelf updateSize];
    }];

    self.endEditingObserver = [NSNotificationCenter.defaultCenter addObserverForName:UITextViewTextDidEndEditingNotification object:self queue:nil usingBlock:^(NSNotification* note) {
        [weakSelf updateSize];
    }];
}

#pragma mark - Initializers

-(void) dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self.changeObserver];
    [NSNotificationCenter.defaultCenter removeObserver:self.endEditingObserver];

    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

-(id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

-(id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

-(id) initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

@end
