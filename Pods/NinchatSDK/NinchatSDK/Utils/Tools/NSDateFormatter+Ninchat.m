//
//  NSDateFormatter+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NSDateFormatter+Ninchat.h"

@implementation NSDateFormatter (Ninchat)

+(NSDateFormatter*) shortTimeFormatter {
    static dispatch_once_t once;
    static NSDateFormatter* formatter;

    dispatch_once(&once, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    });

    return formatter;
}

@end
