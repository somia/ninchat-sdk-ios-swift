//
//  QueueViewController.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 09/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NINBaseViewController.h"

@class NINSessionManager;
@class NINQueue;

/** Displays a waiting view while the user is in a queue. */
@interface NINQueueViewController : NINBaseViewController

/** Queue to connect to */
@property (nonatomic, strong) NINQueue* queueToJoin;

@end
