//
//  NINExpandingTextView.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 04/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NINExpandingTextView : UITextView

@property (nonatomic, assign) IBInspectable CGFloat maximumHeight;

@end

NS_ASSUME_NONNULL_END
