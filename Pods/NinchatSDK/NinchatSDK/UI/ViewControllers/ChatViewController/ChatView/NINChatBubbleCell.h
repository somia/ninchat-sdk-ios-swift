//
//  NINChatBubbleCell.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"

@protocol NINChannelMessage;
@class NINSiteConfiguration;
@class NINUserTypingMessage;
@class NINFileInfo;
@class NINVideoThumbnailManager;
@class NINAvatarConfig;
@class NINComposeContentView;

typedef void (^imagePressedCallback)(NINFileInfo* attachment, UIImage* image);
typedef void (^uiComposeSendPressedCallback)(NINComposeContentView* composeContentView);
typedef void (^uiComposeStateUpdateCallback)(NSArray* composeState);

/** Rerepsents a chat message (in a 'bubble') in the chat view. */
@interface NINChatBubbleCell : UITableViewCell

@property (nonatomic, strong) NINVideoThumbnailManager* videoThumbnailManager;
@property (nonatomic, copy) imagePressedCallback imagePressedCallback;
/** Custom getter and setter for uiComposeSendPressedCallback pass the object through to composeContentView. */
@property (nonatomic, copy) uiComposeSendPressedCallback uiComposeSendPressedCallback;
@property (nonatomic, copy) uiComposeStateUpdateCallback uiComposeStateUpdateCallback;
@property (nonatomic, copy) emptyBlock cellConstraintsUpdatedCallback;

-(void) populateWithChannelMessage:(NSObject<NINChannelMessage>*)message siteConfiguration:(NINSiteConfiguration*)siteConfiguration imageAssets:(NSDictionary<NINImageAssetKey, UIImage*>*)imageAssets colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets agentAvatarConfig:(NINAvatarConfig*)agentAvatarConfig userAvatarConfig:(NINAvatarConfig*)userAvatarConfig composeState:(NSArray*) composeState;

-(void) populateWithUserTypingMessage:(NINUserTypingMessage*)message imageAssets:(NSDictionary<NINImageAssetKey, UIImage*>*)imageAssets colorAssets:(NSDictionary<NINColorAssetKey, UIColor*>*)colorAssets agentAvatarConfig:(NINAvatarConfig*)agentAvatarConfig;

@end
