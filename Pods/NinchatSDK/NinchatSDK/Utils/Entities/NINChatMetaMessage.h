//
//  NINChatMetaMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINChatMessage.h"

/** A meta message displays meta information in the chat view such as "channel joined", "chat ended". etc. */
@interface NINChatMetaMessage : NSObject <NINChatMessage>

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

/** Message text. */
@property (nonatomic, strong, readonly) NSString* text;

/** Title for Close Chat button, or nil for no such button. */
@property (nonatomic, strong, readonly) NSString* closeChatButtonTitle;

/** Creates a new meta message. */
+(instancetype) messageWithText:(NSString*)text timestamp:(NSDate*)timestamp closeChatButtonTitle:(NSString*)closeChatButtonTitle;

@end
