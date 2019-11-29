//
//  UIImageView+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import AFNetworking;

#import "UIImageView+Ninchat.h"
#import "NINToast.h"

@implementation UIImageView (Ninchat)

-(void) setImageURL:(NSString*)url {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    __weak typeof(self) weakSelf = self;

    [self setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        weakSelf.image = image;
        NSLog(@"Set image: %@", weakSelf.image);

        if (response != nil) {
            NSLog(@"Animating the new image in.");
            // The image got loaded over the internet; fade it in.
            weakSelf.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.alpha = 1;
            } completion:^(BOOL finished) {
            }];
        }
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
        [NINToast showWithErrorMessage:@"Failed to fetch image" callback:nil];
    }];
}

@end
