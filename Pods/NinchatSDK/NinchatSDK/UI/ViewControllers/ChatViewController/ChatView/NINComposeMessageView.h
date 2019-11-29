//
//  NINComposeMessageView.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 15/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINChatBubbleCell.h"
#import "NINSessionManager.h"
#import "NINUIComposeMessage.h"
#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"

/** Represents a single ui/compose object's UI within a NINComposeMessageView. */
@interface NINComposeContentView : UIView

/** Compose message as a dictionary, including current selection status. */
@property (nonatomic, strong, readonly) NSDictionary* composeMessageDict;

/** Set send button appearance to initial state in response to send failing; also called in initialisation. */
-(void) sendActionFailed;

@end

/** Represents ui/compose messages's content within a NINChatBubbleCell. */
@interface NINComposeMessageView : UIView

/** Send button callback. */
@property (nonatomic, copy) uiComposeSendPressedCallback uiComposeSendPressedCallback;
/** State update callback. */
@property (nonatomic, copy) uiComposeStateUpdateCallback uiComposeStateUpdateCallback;

-(void) clear;
-(void) populateWithComposeMessage:(NINUIComposeMessage*)message siteConfiguration:(NINSiteConfiguration*)siteConfiguration colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets composeState:(NSArray*)composeState;

@end
