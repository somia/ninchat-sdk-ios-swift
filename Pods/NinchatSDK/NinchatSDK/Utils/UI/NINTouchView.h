//
//  NINTouchView.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 30/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

/**
 This UIView subclass calls its callback block as soon as it is touched.
 It is useful eg. for detecting touches on a part of screen, like when a
 the keyboard is visible and you want to hide it after tapping elsewhere on screen.
 */
@interface NINTouchView : UIView

/** Called when the view has been touched. */
@property (nonatomic, copy) emptyBlock touchCallback;

@end
