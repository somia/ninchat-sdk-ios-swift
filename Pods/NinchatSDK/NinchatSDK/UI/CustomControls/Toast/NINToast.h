//
//  NINToast.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

@interface NINToast : UIView

/** Shows an error message for a while. Callback (if defined) is called when the toast has disappeared. */
+(void) showWithErrorMessage:(NSString*)message callback:(emptyBlock)callback;
+(void) showWithErrorMessage:(NSString*)message touchedCallback:(emptyBlock)touchedCallback callback:(emptyBlock)callback;

/** Shows an info message for a while. Callback (if defined) is called when the toast has disappeared. */
+(void) showWithInfoMessage:(NSString*)message callback:(emptyBlock)callback;

@end
