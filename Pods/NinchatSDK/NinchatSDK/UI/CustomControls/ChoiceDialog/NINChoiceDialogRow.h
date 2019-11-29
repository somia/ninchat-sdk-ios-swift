//
//  NINChoiceDialogRow.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 04/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NINChoiceDialogRow : UIView

+(NINChoiceDialogRow*) rowWithTitle:(NSString*)title pressedCallback:(emptyBlock)pressedCallback;

@end

NS_ASSUME_NONNULL_END
