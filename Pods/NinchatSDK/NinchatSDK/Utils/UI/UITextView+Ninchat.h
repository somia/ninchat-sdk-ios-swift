//
//  UITextView+Ninchat.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (Ninchat)

/**
 * Enables HTML formatting of the input text. If the text doesnt seem to include any
 * such formatting, it is used as such.
 */
-(void) setFormattedText:(NSString*)text;

@end
