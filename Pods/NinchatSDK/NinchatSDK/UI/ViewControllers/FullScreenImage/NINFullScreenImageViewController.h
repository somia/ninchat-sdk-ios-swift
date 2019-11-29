//
//  NINFullScreenImageViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINBaseViewController.h"

@class NINFileInfo;

@interface NINFullScreenImageViewController : NINBaseViewController

/** The image to display. */
@property (nonatomic, strong) UIImage* image;

/** The attachment object representing the image. */
@property (nonatomic, strong) NINFileInfo* attachment;

@end
