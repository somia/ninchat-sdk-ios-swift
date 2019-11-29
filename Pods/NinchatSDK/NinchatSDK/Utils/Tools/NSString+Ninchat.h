//
//  NSString+Ninchat.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Ninchat)

-(NSAttributedString*) htmlAttributedStringWithFont:(UIFont*)font;

/** Returns YES if the string appears to have html / xml tags, eg <br> <p> <foo/> </bar> etc */
-(BOOL) containsTags;

@end
