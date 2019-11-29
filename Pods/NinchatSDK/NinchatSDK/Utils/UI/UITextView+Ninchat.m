//
//  UITextView+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "UITextView+Ninchat.h"
#import "NSString+Ninchat.h"

@implementation UITextView (Ninchat)

-(void) setFormattedText:(NSString*)text {
    if (text.containsTags) {
        self.attributedText = [text htmlAttributedStringWithFont:self.font];
    } else {
        self.text = text;
    }
}

@end
