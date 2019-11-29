//
//  NINNavigationBar.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 10/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

/** Custom "navigation bar" for the SDK UI views. */
@interface NINNavigationBar : UIView

/** Called when the close button was pressed. */
@property (nonatomic, copy) emptyBlock closeButtonPressedCallback;

@end

/** Storyboard/xib-embeddable subclass of NINNavigationBar */
@interface NINEmbeddableNavigationBar : NINNavigationBar

@end
