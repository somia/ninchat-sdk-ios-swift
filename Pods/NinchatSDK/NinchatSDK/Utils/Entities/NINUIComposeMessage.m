//
//  NINUIComposeMessage.m
//  NinchatSDK
//
//  Created by Kosti Jokinen on 08/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINUIComposeMessage.h"

@interface NINUIComposeContent ()

// Writable private definitions for the properties
@property (nonatomic, strong) NSString* className;
@property (nonatomic, strong) NSString* element;
@property (nonatomic, strong) NSString* href;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* label;
@property (nonatomic, strong) NSArray<NSDictionary*>* options;

@end

@implementation NINUIComposeContent

-(NSDictionary*) dictWithOptions:(NSArray<NSDictionary*>*)options {
    NSMutableDictionary* mutableDict = [[NSMutableDictionary alloc] init];
    mutableDict[@"element"] = self.element;
    if (self.href != nil) {
        mutableDict[@"href"] = self.href;
    }
    if (self.className != nil) {
        mutableDict[@"class"] = self.className;
    }
    if (self.uid != nil) {
        mutableDict[@"id"] = self.uid;
    }
    if (self.label != nil) {
        mutableDict[@"label"] = self.label;
    }
    if (options != nil) {
        mutableDict[@"options"] = options;
    } else if (self.options != nil) {
        mutableDict[@"options"] = self.options;
    }
    if (self.name != nil) {
        mutableDict[@"name"] = self.name;
    }
    return mutableDict;
}

+(NINUIComposeContent*) contentWithClassName:(NSString*)className element:(NSString*)element href:(NSString*)href uid:(NSString*)uid name:(NSString*)name label:(NSString*)label options:(NSArray<NSDictionary*>*)options {
    NINUIComposeContent* content = [NINUIComposeContent new];
    content.className = className;
    content.element = element;
    content.href = href;
    content.name = name;
    content.label = label;
    content.options = options;
    
    return content;
}

@end

@interface NINUIComposeMessage ()

// Writable private definitions for the properties
@property (nonatomic, strong) NSString* messageID;
@property (nonatomic, assign) BOOL mine;
@property (nonatomic, strong) NINChannelUser* sender;
@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSArray<NINUIComposeContent*>* content;

@end

@implementation NINUIComposeMessage

-(NSInteger) sendPressedIndex {
    for (NSInteger i = 0; i < self.content.count; i++) {
        if (self.content[i].sendPressed) {
            return i;
        }
    }
    
    return -1;
}

+(NINUIComposeMessage*) messageWithID:(NSString*)messageID sender:(NINChannelUser*)sender timestamp:(NSDate*)timestamp mine:(BOOL)mine payload:(NSArray*)payload {
    NINUIComposeMessage* msg = [NINUIComposeMessage new];
    msg.messageID = messageID;
    msg.sender = sender;
    msg.timestamp = timestamp;
    msg.mine = mine;
    msg.series = NO;
    
    NSMutableArray* mutableContent = [[NSMutableArray alloc] init];
    for (NSDictionary* dict in payload) {
        [mutableContent addObject:[NINUIComposeContent contentWithClassName:dict[@"class"] element:dict[@"element"] href:dict[@"href"] uid:dict[@"id"] name:dict[@"name"] label:dict[@"label"] options:dict[@"options"]]];
    }
    msg.content = mutableContent;
    
    return msg;
}

@end
