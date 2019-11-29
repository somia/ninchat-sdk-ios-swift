//
//  NINChatMetaMessage.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatMetaMessage.h"

@interface NINChatMetaMessage ()

@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSString* closeChatButtonTitle;

@end

@implementation NINChatMetaMessage

-(NSString*) description {
    return [NSString stringWithFormat:@"NINChatMetaMessage text: %@, timestamp: %@", self.text, self.timestamp];
}

+(instancetype) messageWithText:(NSString*)text timestamp:(NSDate*)timestamp closeChatButtonTitle:(NSString*)closeChatButtonTitle {
    NINChatMetaMessage* msg = [NINChatMetaMessage new];
    msg.text = text;
    msg.timestamp = timestamp;
    msg.closeChatButtonTitle = closeChatButtonTitle;

    return msg;
}

@end
