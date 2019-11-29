//
//  NINVideoThumbnailManager.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 01/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import AVFoundation;

#import "NINVideoThumbnailManager.h"
#import "NINUtils.h"

@interface NINVideoThumbnailManager ()

@property (nonatomic, strong) NSCache* imageCache;

@end

@implementation NINVideoThumbnailManager

-(void) getVideoThumbnail:(NSString*)videoURL completion:(extractThumbnailCallback)completion {
    NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

    // Check if we have a cached thumbnail
    UIImage* cached = [self.imageCache objectForKey:videoURL];
    if (cached != nil) {
        completion(nil, YES, cached);
        return;
    }

    // Cache miss; must extract it from the video
    runInBackgroundThread(^{
        AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:videoURL]];

        // Grab the thumbnail a few seconds into the video
        CMTime duration = [asset duration];
        CMTime thumbTime = CMTimeMakeWithSeconds(2, 30);
        thumbTime = CMTimeMaximum(duration, thumbTime);
        
        // Create an AVAssetImageGenerator that applies the proper image orientation
        AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;

        // Extract the thumbnail image as a snapshot from a video frame
        NSError* error = nil;
        CGImageRef imageRef = [generator copyCGImageAtTime:thumbTime actualTime:nil error:&error];
        UIImage* thumbnail = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);

        [self.imageCache setObject:thumbnail forKey:videoURL];

        runOnMainThread(^{
            completion(error, NO, thumbnail);
        });
    });
}

-(id) init {
    self = [super init];

    if (self != nil) {
        self.imageCache = [NSCache new];
        self.imageCache.name = @"ninchatsdk.VideoThumbnailImageCache";
    }

    return self;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end
