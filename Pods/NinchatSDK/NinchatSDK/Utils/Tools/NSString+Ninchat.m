//
//  NSString+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import "NSMutableAttributedString+Ninchat.h"
#import "NSString+Ninchat.h"

@implementation NSString (Ninchat)

-(NSAttributedString*) htmlAttributedStringWithFont:(UIFont*)font {
    NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithData:data options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:NULL error:NULL];
    [attrString overrideFont:font];

    return attrString;
}

-(BOOL) containsTags {
    NSString* matchPattern = @"(<\\w+>|<\\w+/>|</\\w+>)";
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:matchPattern options:0 error:&error];
    NSCAssert(error == nil, @"Regex creation failed");
    NSArray<NSTextCheckingResult*>* results = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
//    if (results.count > 0) {
//        NSTextCheckingResult* res = results.firstObject;
//        NSString* match = [self substringWithRange:res.range];
//        NSLog(@"Match: '%@'", match);
//    }

    return results.count > 0;
}

@end
