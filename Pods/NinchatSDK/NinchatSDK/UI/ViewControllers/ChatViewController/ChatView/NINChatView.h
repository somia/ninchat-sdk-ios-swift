//
//  NINChatView.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 19/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINChatMessage.h"
#import "NINComposeMessageView.h"
#import "NINPublicTypes.h"

@class NINChatView;
@class NINFileInfo;
@class NINSessionManager;

/** Data source for the chat view. */
@protocol NINChatViewDataSource

/** How many messages there are. */
-(NSInteger) numberOfMessagesForChatView:(NINChatView*)chatView;

/** Returns the chat message at given index. */
-(id<NINChatMessage>) chatView:(NINChatView*)chatView messageAtIndex:(NSInteger)index;

@end

/** Delegate for the chat view. */
@protocol NINChatViewDelegate

/** An image in a cell was selected (tapped). */
-(void) chatView:(NINChatView*)chatView imageSelected:(UIImage*)image forAttachment:(NINFileInfo*)attachment;

/** "Close Chat" button was pressed inside the chat view; the used requests closing the chat SDK. */
-(void) closeChatRequestedByChatView:(NINChatView*)chatView;

/** "Send" button was pressed in a ui/compose type message. */
-(void) uiActionSentByComposeContentView:(NINComposeContentView*)composeContentView;

@end

@interface NINChatView : UIView

/** My data source. */
@property (nonatomic, weak) id<NINChatViewDataSource> dataSource;

/** My delegate. */
@property (nonatomic, weak) id<NINChatViewDelegate> delegate;

/** Chat session manager. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** A new message was added to given index. Updates the view. */
-(void) newMessageWasAddedAtIndex:(NSInteger)index;

/** A message was removed from given index. */
-(void) messageWasRemovedAtIndex:(NSInteger)index;

@end

/** Storyboard/xib-embeddable subclass of NINChatView */
@interface NINEmbeddableChatView : NINChatView

@end
