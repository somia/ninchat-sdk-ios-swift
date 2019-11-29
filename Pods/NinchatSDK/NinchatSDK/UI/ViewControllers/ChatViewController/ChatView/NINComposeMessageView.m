//
//  NINComposeMessageView.m
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINChatBubbleCell.h"
#import "NINComposeMessageView.h"
#import "NINUtils.h"

static CGFloat const kButtonHeight = 45;
static CGFloat const kVerticalMargin = 10;

static UIColor* buttonBlue;
static UIColor* buttonGrey;
static UIFont* labelFont;

typedef void (^uiComposeElementStateUpdateCallback)(NSDictionary* composeState);

@interface NINComposeContentView ()

// compose options received from the backend and displayed
@property (nonatomic, strong) NSArray<NSMutableDictionary*>* options;

// originally received ui/compose object, public getter returns modified options
@property (nonatomic, strong) NINUIComposeContent* originalContent;

// title label initialised once, hidden for button elements
@property (nonatomic, strong) UILabel* titleLabel;
// send button initialised once, used as the single button for button elements
@property (nonatomic, strong) UIButton* sendButton;
// select element option buttons, recreated on reuse
@property (nonatomic, strong) NSArray<UIButton*>* optionButtons;

/*
 Current state to be synced with NINChatView to persist state across cell recycling.
 "select" type objects use option indices as keys, selection states as values, other
 element types currently track nothing.
 */
@property (nonatomic, strong) NSMutableDictionary* composeState;

@property (nonatomic, copy) uiComposeSendPressedCallback uiComposeSendPressedCallback;
@property (nonatomic, copy) uiComposeElementStateUpdateCallback uiComposeElementStateUpdateCallback;

@end

@implementation NINComposeContentView

-(CGFloat) intrinsicHeight {
    if ([self.originalContent.element isEqualToString:kUIComposeMessageElementSelect]) {
        // + 1 to button count from send button, additional margin top, bottom handled in superview
        return self.titleLabel.intrinsicContentSize.height
        + (self.optionButtons.count + 1) * kButtonHeight
        + self.optionButtons.count * kVerticalMargin;
    } else if ([self.originalContent.element isEqualToString:kUIComposeMessageElementButton]) {
        return kButtonHeight;
    } else {
        return 0;
    }
}

-(void) applyButtonStyle:(UIButton*)button selected:(BOOL)selected {
    UIColor* mainColor = (button == self.sendButton) ? buttonBlue : buttonGrey;
    button.layer.cornerRadius = kButtonHeight / 2;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = mainColor.CGColor;
    if (selected) {
        button.layer.borderWidth = 0;
        [button setBackgroundImage:imageFrom(buttonBlue) forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    } else {
        button.layer.borderWidth = 2;
        [button setBackgroundImage:imageFrom(UIColor.whiteColor) forState:UIControlStateNormal];
        [button setTitleColor:mainColor forState:UIControlStateNormal];
    }
}

-(NSDictionary*) composeMessageDict {
    return [self.originalContent dictWithOptions:self.options];
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    if ([self.originalContent.element isEqualToString:kUIComposeMessageElementSelect]) {
        CGFloat titleHeight = self.titleLabel.intrinsicContentSize.height;
        self.titleLabel.frame = CGRectMake(0, 0, self.titleLabel.intrinsicContentSize.width, titleHeight);
        
        CGFloat y = titleHeight + kVerticalMargin;
        for (UIButton* button in self.optionButtons) {
            button.frame = CGRectMake(0, y, self.bounds.size.width, kButtonHeight);
            y += kButtonHeight + kVerticalMargin;
        }
        
        CGFloat sendButtonWidth = self.sendButton.intrinsicContentSize.width + 60;
        self.sendButton.frame = CGRectMake(self.bounds.size.width - sendButtonWidth, y, sendButtonWidth, kButtonHeight);
    } else if ([self.originalContent.element isEqualToString:kUIComposeMessageElementButton]) {
        self.sendButton.frame = self.bounds;
    }
}

-(void) clear {
    self.originalContent = nil;
    if (self.optionButtons != nil) {
        for (UIButton* button in self.optionButtons) {
            [button removeFromSuperview];
        }
    }
    self.options = nil;
    self.optionButtons = nil;
}

-(void) removeSendButtonAction {
    [self.sendButton removeTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
}

-(void) pressed:(UIButton*)button {
    if (button == self.sendButton) {
        self.uiComposeSendPressedCallback(self);
        [self applyButtonStyle:button selected:YES];
        return;
    }
    
    for (int i=0; i<self.optionButtons.count; ++i) {
        if (button == self.optionButtons[i]) {
            BOOL selected = ![[self.options[i] valueForKey:@"selected"] boolValue];
            self.options[i][@"selected"] = @(selected);
            self.composeState[@(i)] = @(selected);
            [self applyButtonStyle:button selected:selected];
            self.uiComposeElementStateUpdateCallback(self.composeState);
            return;
        }
    }
}

-(void) populateWithComposeMessage:(NINUIComposeContent*)composeContent siteConfiguration:(NINSiteConfiguration*)siteConfiguration colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets composeState:(NSDictionary*)composeState enableSendButton:(BOOL)enableSendButton isSelected:(BOOL)isSelected {
    
    self.originalContent = composeContent;
    
    // create title label and send button once
    if (self.titleLabel == nil) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = labelFont;
        self.titleLabel.textColor = [UIColor blackColor];
        UIColor* bubbleTextColor = colorAssets[NINColorAssetKeyChatBubbleLeftText];
        if (bubbleTextColor != nil) {
            self.titleLabel.textColor = bubbleTextColor;
        }
        [self addSubview:self.titleLabel];
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self applyButtonStyle:self.sendButton selected:isSelected];
        self.sendButton.titleLabel.font = labelFont;
        
        if (enableSendButton) {
            [self.sendButton addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [self addSubview:self.sendButton];
    }
    
    if ([composeContent.element isEqualToString:kUIComposeMessageElementButton]) {
        [self.titleLabel setHidden:YES];
        [self.sendButton setTitle:composeContent.label forState:UIControlStateNormal];
        self.sendButton.layer.borderWidth = 1;
        self.composeState = nil;
    } else if ([composeContent.element isEqualToString:kUIComposeMessageElementSelect]) {
        [self.titleLabel setHidden:NO];
        [self.titleLabel setText:composeContent.label];
        NSString* sendButtonText = [siteConfiguration valueForKey:@"sendButtonText"];
        if (sendButtonText != nil) {
            [self.sendButton setTitle:sendButtonText forState:UIControlStateNormal];
        } else {
            [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        }
        self.sendButton.layer.borderWidth = 2;
        
        // clear existing option buttons
        if (self.optionButtons != nil) {
            for (UIButton* button in self.optionButtons) {
                [button removeFromSuperview];
            }
        }
        
        // recreate options dict to add the "selected" fields
        NSMutableArray<NSMutableDictionary*>* options = [NSMutableArray new];
        NSMutableArray<UIButton*>* optionButtons = [NSMutableArray new];
        self.composeState = [composeState mutableCopy];
        if (composeState == nil) {
            self.composeState = [NSMutableDictionary new];
        }

        for (int i=0; i<composeContent.options.count; ++i) {
            NSMutableDictionary* newOption = [composeContent.options[i] mutableCopy];
            NSNumber* selected = composeState[@(i)];
            if (selected == nil) {
                selected = @NO;
                self.composeState[@(i)] = @NO;
            }
            newOption[@"selected"] = selected;
            
            UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.titleLabel.font = labelFont;
            [self applyButtonStyle:button selected:[selected boolValue]];
            [button setTitle:newOption[@"label"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            
            [options addObject:newOption];
            [optionButtons addObject:button];
        }
        
        self.options = options;
        self.optionButtons = optionButtons;
    }
}

// update ui to reflect that sending failed
-(void) sendActionFailed {
    // no ui feedback at the moment
}

@end

@interface NINComposeMessageView ()

// content views
@property (nonatomic, strong) NSMutableArray<NINComposeContentView*>* contentViews;

// ui/compose objects's current states
@property (nonatomic, strong) NSMutableArray<NSDictionary*>* composeStates;

@end

@implementation NINComposeMessageView

-(BOOL) isActive {
    return (self.contentViews.count > 0) && !self.contentViews[0].isHidden;
}

-(CGFloat) intrinsicHeight {
    if ([self isActive]) {
        CGFloat height = 0;
        for (NINComposeContentView* view in self.contentViews) {
            height += [view intrinsicHeight];
        }
        
        // Add margin between all views
        height += kVerticalMargin * (self.contentViews.count - 1);
        
        return height;
    } else {
        return 0;
    }
}

-(CGSize) intrinsicContentSize {
    if ([self isActive]) {
        return CGSizeMake(CGFLOAT_MAX, [self intrinsicHeight]);
    } else {
        return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
    }
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    CGFloat y = 0;
    
    for (NINComposeContentView* view in self.contentViews) {
        CGFloat height = [view intrinsicHeight];
        view.frame = CGRectMake(0, y, self.bounds.size.width, height);
        y += height + kVerticalMargin;
    }
}

-(void) clear {
    for (NINComposeContentView* view in self.contentViews) {
        [view clear];
        [view setHidden:YES];
    }
    
    [self invalidateIntrinsicContentSize];
}

-(void) populateWithComposeMessage:(NINUIComposeMessage*)composeMessage siteConfiguration:(NINSiteConfiguration*)siteConfiguration colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets composeState:(NSArray*)composeState {
    
    // Note, this method will reuse existing content views already allocated.
    
    if (self.contentViews.count < composeMessage.content.count) {
        // There are fewer content views than needed; add the missing amount
        NSUInteger oldCount = self.contentViews.count;
        for (int i = 0; i < composeMessage.content.count - oldCount; ++i) {
            NINComposeContentView* contentView = [[NINComposeContentView alloc] init];
            [self addSubview:contentView];
            [self.contentViews addObject:contentView];
        }
    } else if (composeMessage.content.count < self.contentViews.count) {
        // There are more content views than needed; remove the extra ones
        [self.contentViews removeObjectsInRange:NSMakeRange(composeMessage.content.count, self.contentViews.count - composeMessage.content.count)];
    }
    
    if (composeState == nil) {
        self.composeStates = [[NSMutableArray alloc] init];
    } else {
        self.composeStates = [composeState mutableCopy];
    }
    
    __weak typeof(self) weakSelf = self;
    BOOL enableSendButtons = (composeMessage.sendPressedIndex == -1);
    
    for (int i = 0; i < self.contentViews.count; i++) {
        [self.contentViews[i] populateWithComposeMessage:composeMessage.content[i] siteConfiguration:siteConfiguration colorAssets:colorAssets composeState:composeState[i] enableSendButton:enableSendButtons isSelected:(composeMessage.sendPressedIndex == i)];
        self.contentViews[i].uiComposeSendPressedCallback = ^(NINComposeContentView* composeContentView) {
            composeMessage.content[i].sendPressed = YES;
            
            // Make the send buttons unclickable for this message
            for (int j = 0; j < self.contentViews.count; j++) {
                [weakSelf.contentViews[j] removeSendButtonAction];
            }
            weakSelf.uiComposeSendPressedCallback(composeContentView);
        };
        [self.contentViews[i] setHidden:NO];
        self.contentViews[i].uiComposeElementStateUpdateCallback = ^(NSDictionary *composeState) {
            weakSelf.composeStates[i] = composeState;
            weakSelf.uiComposeStateUpdateCallback(weakSelf.composeStates);
        };
    }
    
    [self invalidateIntrinsicContentSize];
}

-(void) awakeFromNib {
    [super awakeFromNib];
    if (buttonBlue == nil) {
        buttonBlue = [UIColor colorWithRed:(CGFloat)0x49/0xFF green:(CGFloat)0xAC/0xFF blue:(CGFloat)0xFD/0xFF alpha:1];
        buttonGrey = [UIColor colorWithRed:(CGFloat)0x99/0xFF green:(CGFloat)0x99/0xFF blue:(CGFloat)0x99/0xFF alpha:1];
        /*
         This should be source sans pro, but the custom font fails to initialise.
         It appears it's actually broken everywhere else too, so for the sake of
         getting this feature out we'll just match the current look for now.
         */
        labelFont = [UIFont fontWithName:@"Helvetica" size:16];
    }
    
    self.contentViews = [[NSMutableArray alloc] init];
}

@end
