//
//  NINFileInfo.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 17/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINFileInfo.h"
#import "NINSessionManager.h"

@interface NINFileInfo ()

@property (nonatomic, weak) NINSessionManager* sessionManager;

// Writable versions of public properties
@property (nonatomic, strong) NSString* fileID;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* mimeType;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSDate* urlExpiry;

@end

@implementation NINFileInfo

-(NSString*) description {
    return [NSString stringWithFormat:@"ID: %@, mimeType: %@, size: %ld", self.fileID, self.mimeType, (long)self.size];
}

-(BOOL) isImage {
    return [self.mimeType hasPrefix:@"image/"];
}

-(BOOL) isVideo {
    return [self.mimeType hasPrefix:@"video/"];
}

-(BOOL) isPDF {
    return [self.mimeType isEqualToString:@"application/pdf"];
}

-(BOOL) isImageOrVideo {
    return self.isImage || self.isVideo;
}

-(void) updateInfoWithCompletionCallback:(updateFileInfoCallback)completion {
    // The URL must not expire within the next 15 minutes
    NSDate* comparisonDate = [NSDate dateWithTimeIntervalSinceNow:-(15 * 60)];

    if ((self.url == nil) || (self.urlExpiry == nil) || ([self.urlExpiry compare:comparisonDate] == NSOrderedAscending)) {
        NSLog(@"Must update file info; call describe_file");
        [self.sessionManager describeFile:self.fileID completion:^(NSError* error, NSDictionary* fileInfo) {
            if (error != nil) {
                completion(error, YES);
            } else {
                self.url = fileInfo[@"url"];
                self.urlExpiry = fileInfo[@"urlExpiry"];
                self.aspectRatio = [fileInfo[@"aspectRatio"] floatValue];
                completion(nil, YES);
            }
        }];
    } else {
        NSLog(@"No need to update file, it is up to date.");
        // No need to update; everything is up to date
        completion(nil, NO);
    }
}

+(instancetype) fileWithSessionManager:(NINSessionManager*)sessionManager fileID:(NSString*)fileID name:(NSString*)name mimeType:(NSString*)mimeType size:(NSInteger)size {

    NINFileInfo* info = [NINFileInfo new];
    info.sessionManager = sessionManager;
    info.fileID = fileID;
    info.name = name;
    info.mimeType = mimeType;
    info.size = size;

    return info;
}

@end
