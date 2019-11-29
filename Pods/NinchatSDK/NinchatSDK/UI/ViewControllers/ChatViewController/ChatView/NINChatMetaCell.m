//
//  NINChatMetaCell.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatMetaCell.h"
#import "NINCloseChatButton.h"
#import "NINChatMetaMessage.h"

@interface NINChatMetaCell ()

@property (nonatomic, strong) IBOutlet UILabel* metaTextLabel;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* buttonContainerHeightConstraint;
@property (nonatomic, strong) IBOutlet NINCloseChatButton* closeChatButton;

@end

@implementation NINChatMetaCell

-(void) populateWithMessage:(NINChatMetaMessage*)message colorAssets:(NSDictionary<NINColorAssetKey,UIColor*>*)colorAssets session:(NINChatSession*)session {

    __weak typeof(self) weakSelf = self;

    // Customize assets
    UIColor* labelColor = colorAssets[NINColorAssetKeyInfoText];
    if (labelColor != nil) {
        self.metaTextLabel.textColor = labelColor;
    }

    self.metaTextLabel.text = message.text;

    if (message.closeChatButtonTitle == nil) {
        self.buttonContainerHeightConstraint.constant = 0;
        self.buttonContainerHeightConstraint.active = YES;
        self.closeChatButton.pressedCallback = nil;
    } else {
        self.buttonContainerHeightConstraint.active = NO;
        [self.closeChatButton setButtonTitle:message.closeChatButtonTitle];
        [self.closeChatButton overrideAssetsWithSession:session];
        self.closeChatButton.pressedCallback = ^{
            weakSelf.closeChatCallback();
        };
    }
}

-(void) awakeFromNib {
    [super awakeFromNib];

    // Rotate the cell 180 degrees; we will use the table view upside down
    self.transform = CGAffineTransformMakeRotation(M_PI);

    // The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = UIScreen.mainScreen.scale;
}

@end
