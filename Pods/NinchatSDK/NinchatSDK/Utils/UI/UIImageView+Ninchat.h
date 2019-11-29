//
//  UIImageView+Ninchat.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Ninchat)

/** Loads an image over HTTP or from a local cache, if available. Fades the loaded image in. */
-(void) setImageURL:(NSString*)url;

@end
