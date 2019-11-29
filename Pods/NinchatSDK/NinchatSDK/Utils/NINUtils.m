//
//  Utils.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AFNetworking;

#import "NINUtils.h"
#import "NINInitialViewController.h"

// Site config URL pattern. Populate with kServerHostName & configuration key
static NSString* const kSiteConfigUrlPattern = @"https://%@/config/%@";

NSError* newError(NSString* msg) {
    return [NSError errorWithDomain:@"NinchatSDK" code:1 userInfo:@{@"message": msg}];
}

void runInBackgroundThread(emptyBlock block) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block);
}

void runOnMainThread(emptyBlock block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void runOnMainThreadWithDelay(emptyBlock _Nonnull block, NSTimeInterval delay) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

void postNotification(NSString* notificationName, NSDictionary* userInfo) {
    runOnMainThread(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:userInfo];
    });
}

id fetchNotification(NSString* notificationName, notificationBlock _Nonnull block) {
    id __block observer = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (block(note)) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
    }];

    return observer;
}

NSLayoutConstraint* constrain(UIView* view1, UIView* view2, NSLayoutAttribute attr) {
    return [NSLayoutConstraint constraintWithItem:view1 attribute:attr relatedBy:NSLayoutRelationEqual toItem:view2 attribute:attr multiplier:1 constant:0];
}

NSArray<NSLayoutConstraint*>* constrainToMatch(UIView* view1, UIView* view2) {
    return @[constrain(view1, view2, NSLayoutAttributeTop),
             constrain(view1, view2, NSLayoutAttributeRight),
             constrain(view1, view2, NSLayoutAttributeBottom),
             constrain(view1, view2, NSLayoutAttributeLeft)];
}

NSBundle* findResourceBundle() {
    NSBundle* classBundle = [NSBundle bundleForClass:[NINInitialViewController class]];
    NSCAssert(classBundle != nil, @"Nil classBundle");

    NSURL* bundleURL = [classBundle URLForResource:@"NinchatSDKUI" withExtension:@"bundle"];
    if (bundleURL == nil) {
        // This path is taken when using the SDK from a prebuilt .framework.
        return classBundle;
    } else {
        // This path is taken when using the SDK via Cocoapods module.
        // Locate our UI resource bundle. This is specified in the podspec file.
        NSBundle* resourceBundle = [NSBundle bundleWithURL:bundleURL];
        NSCAssert(resourceBundle != nil, @"Nil resourceBundle");

        return resourceBundle;
    }
}

UIView* loadFromNib(Class class) {
    NSBundle* bundle = findResourceBundle();
    NSArray* objects = [bundle loadNibNamed:NSStringFromClass(class) owner:nil options:nil];

    NSCAssert([objects.firstObject isKindOfClass:class], @"Invalid class resource");

    return objects.firstObject;
}

void fetchSiteConfig(NSString* serverAddress, NSString* configurationKey, fetchSiteConfigCallbackBlock callbackBlock) {
    NSString* url = [NSString stringWithFormat:kSiteConfigUrlPattern, serverAddress, configurationKey];

    void (^callCallback)(NSDictionary* config, NSError* error) = ^(NSDictionary* config, NSError* error) {
        runOnMainThread(^{
            callbackBlock(config, error);
        });
    };

    AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionTask* task, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            callCallback((NSDictionary*)responseObject, nil);
        } else {
            callCallback(nil, newError([NSString stringWithFormat:@"Invalid responseObject class: %@", [responseObject class]]));
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        callCallback(nil, error);
    }];
}

NSString* guessMIMETypeFromFileName(NSString* fileName) {
    NSString* fileExtension = [[fileName pathExtension] lowercaseString];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
    CFRelease(uti);

    if (mimeType == nil) {
        return @"application/octet-stream";
    }

    return (__bridge NSString*)mimeType;
}

UIImage* imageFrom(UIColor* _Nonnull color) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), true, 0.0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, 1, 1));
    return UIGraphicsGetImageFromCurrentImageContext();
}
