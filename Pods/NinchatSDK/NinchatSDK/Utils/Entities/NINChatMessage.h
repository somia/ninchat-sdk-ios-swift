//
//  NINChatMessage.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Describes a message shown in the chat view UI. */
@protocol NINChatMessage <NSObject>

/** Message timestamp. */
@property (nonatomic, strong, readonly) NSDate* timestamp;

@end
