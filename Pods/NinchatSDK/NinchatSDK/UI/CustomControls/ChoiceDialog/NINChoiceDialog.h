//
//  NINChoiceDialog.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 04/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^choiceDialogCompletionCallback)(BOOL canceled, NSInteger selectedIndex);

NS_ASSUME_NONNULL_BEGIN

@interface NINChoiceDialog : UIView

+(NINChoiceDialog*) showWithOptionTitles:(NSArray<NSString*>*)optionTitles completion:(choiceDialogCompletionCallback)completion;

@end

NS_ASSUME_NONNULL_END
