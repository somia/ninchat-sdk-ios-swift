//
//  NINUIComposeMessage.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 08/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINChannelMessage.h"

static NSString* const kUIComposeMessageElementA = @"a";
static NSString* const kUIComposeMessageElementButton = @"button";
static NSString* const kUIComposeMessageElementSelect = @"select";

@class NINChannelUser;

@interface NINUIComposeContent : NSObject

/** Element class. */
@property (nonatomic, strong, readonly) NSString* className;

/** Element type. API specifies "a", "button" and "select", SDK currently supports "button" and "select". */
@property (nonatomic, strong, readonly) NSString* element;

/** Link target for element type "a". */
@property (nonatomic, strong, readonly) NSString* href;

/** Element unique identifier. */
@property (nonatomic, strong, readonly) NSString* uid;

/** Element name. */
@property (nonatomic, strong, readonly) NSString* name;

/** A label or a descriptive text depending on the element. Text prompt on "select". */
@property (nonatomic, strong, readonly) NSString* label;

/** Array of NINUIComposeOption elements for "select" type element. */
@property (nonatomic, strong, readonly) NSArray<NSDictionary*>* options;

/** Indicates that 'send' button has been pressed for this item. */
@property (nonatomic, assign) BOOL sendPressed;

/** Instance data as a dictionary, with options property replaced if parameter is non-nil. */
-(NSDictionary*) dictWithOptions:(NSArray<NSDictionary*>*)options;

+(NINUIComposeContent*) contentWithClassName:(NSString*)className element:(NSString*)element href:(NSString*)href uid:(NSString*)uid name:(NSString*)name label:(NSString*)label options:(NSArray<NSDictionary*>*)options;

@end

@interface NINUIComposeMessage : NSObject<NINChannelMessage>

/**
 * YES if this message is a part in a series, ie. the sender of the previous message
 * also sent this message.
 */
@property (nonatomic, assign) BOOL series;

/** Message payload of ui/compose type content. */
@property (nonatomic, strong, readonly) NSArray<NINUIComposeContent*>* content;

/**
 Indicates the content index of the item for which 'send' button has been pressed.
 Returns -1 if none has been pressed.
 */
-(NSInteger) sendPressedIndex;

+(NINUIComposeMessage*) messageWithID:(NSString*)messageID sender:(NINChannelUser*)sender timestamp:(NSDate*)timestamp mine:(BOOL)mine payload:(NSArray*)payload;

@end

