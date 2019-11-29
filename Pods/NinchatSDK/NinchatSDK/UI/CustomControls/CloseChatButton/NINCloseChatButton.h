//
//  NINCloseChatButton.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 13/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

@class NINChatSession;

@interface NINCloseChatButton : UIView

@property (nonatomic, copy) emptyBlock pressedCallback;

-(void) setButtonTitle:(NSString*)title;
-(void) overrideAssetsWithSession:(NINChatSession*)session;

@end

/** Storyboard/xib-embeddable subclass of NINCloseChatButton */
@interface NINEmbeddableCloseChatButton : NINCloseChatButton

@end
