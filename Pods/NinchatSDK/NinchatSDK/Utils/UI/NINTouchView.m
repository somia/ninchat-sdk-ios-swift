//
//  NINTouchView.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 30/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINTouchView.h"

@implementation NINTouchView

-(void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    self.touchCallback();
}

@end
