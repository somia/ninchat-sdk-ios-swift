//
//  NSMutableAttributedString+Ninchat.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (Ninchat)

/** Overrides the font across the attributed string, keeping font traints. */
-(void) overrideFont:(UIFont*)font;

@end
