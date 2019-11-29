//
//  NINBaseViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 10/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NINSessionManager;
@class NINNavigationBar;

/** Intended base class for all Ninchat SDK view controllers. */
@interface NINBaseViewController : UIViewController <UITextViewDelegate, UINavigationControllerDelegate>

/** Reference to the session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** Reference to the custom navigation bar. */
@property (nonatomic, strong) IBOutlet NINNavigationBar* customNavigationBar;

/** Default handler for show keyboard -event. */
-(void) keyboardWillShow:(NSNotification*)notification;

/** Default handler for hide keyboard -event. */
-(void) keyboardWillHide:(NSNotification*)notification;

@end
