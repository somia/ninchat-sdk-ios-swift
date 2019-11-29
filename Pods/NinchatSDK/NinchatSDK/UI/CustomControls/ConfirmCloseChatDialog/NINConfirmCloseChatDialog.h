//
//  NINConfirmCloseChatDialog.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/11/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINSessionManager;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NINConfirmCloseChatDialogResult) {
    NINConfirmCloseChatDialogResultClose,
    NINConfirmCloseChatDialogResultCancel
};

typedef void (^confirmCloseChatDialogClosedBlock)(NINConfirmCloseChatDialogResult result);

/** Asks the user whether to close the ongoing chat. */
@interface NINConfirmCloseChatDialog : UIView

/** Displays the dialog on top of another view. */
+(instancetype) showOnView:(UIView*)view sessionManager:(NINSessionManager*)sessionManager closedBlock:(confirmCloseChatDialogClosedBlock)closedBlock;

@end

NS_ASSUME_NONNULL_END
