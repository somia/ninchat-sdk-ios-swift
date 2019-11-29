//
//  NINPermissions.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 21/11/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import Photos;

#import "NINPermissions.h"
#import "NINUtils.h"

void checkCaptureDevicePermission(AVMediaType mediaType, callbackWithErrorBlock callback) {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    switch (status) {
        case AVAuthorizationStatusAuthorized:
        {
            NSLog(@"AVCaptureDevice is already authorized.");
            callback(nil);
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                runOnMainThread(^{
                    if (granted) {
                        NSLog(@"User authorized the use of AVCaptureDevice.");
                        callback(nil);
                    } else {
                        NSLog(@"User denied the use of AVCaptureDevice.");
                        callback([NSError errorWithDomain:@"NINPermissions" code:1 userInfo:nil]);
                    }
                });
            }];
            break;
        }
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:
        {
            NSLog(@"AVCaptureDevice is denied / restricted!");
            callback([NSError errorWithDomain:@"NINPermissions" code:1 userInfo:nil]);
            break;
        }
    }
}

void checkMicrophonePermission(callbackWithErrorBlock callback) {
    return checkCaptureDevicePermission(AVMediaTypeAudio, callback);
}

void checkVideoPermission(callbackWithErrorBlock callback) {
    return checkCaptureDevicePermission(AVMediaTypeVideo, callback);
}

void checkPhotoLibraryPermission(callbackWithErrorBlock callback) {
    PHAuthorizationStatus status = PHPhotoLibrary.authorizationStatus;
    switch (status) {
        case PHAuthorizationStatusAuthorized:
        {
            NSLog(@"Photo library is authorized.");
            callback(nil);
            break;
        }
        case PHAuthorizationStatusNotDetermined:
        {
            NSLog(@"Asking the user for Photo Library permission.");
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus newStatus) {
                runOnMainThread(^{
                    if (newStatus == PHAuthorizationStatusAuthorized) {
                        NSLog(@"User authorized use of Photo Library.");
                        callback(nil);
                    } else {
                        NSLog(@"User denied use of Photo Library.");
                        callback([NSError errorWithDomain:@"NINPermissions" code:1 userInfo:nil]);
                    }
                });
            }];
            break;
        }
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
        {
            NSLog(@"Photo library is not authorized.");
            callback([NSError errorWithDomain:@"NINPermissions" code:1 userInfo:nil]);
            break;
        }
    }
}

