//
//  Utils.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 05/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#ifndef NINUtils_h
#define NINUtils_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NINPrivateTypes.h"

/**
 * Run the given block in a background thread.
 */
void runInBackgroundThread(emptyBlock _Nonnull block);

/**
 * Runs the given block on the main thread (queue).
 */
void runOnMainThread(emptyBlock _Nonnull block);

/**
 * Runs the given block on the main thread (queue) after 'delay' seconds.
 */
void runOnMainThreadWithDelay(emptyBlock _Nonnull block, NSTimeInterval delay);

/**
 * Posts a named notification, using the default notification center instance,
 * with given user info data on the main thread.
 */
void postNotification(NSString* _Nonnull notificationName, NSDictionary* _Nonnull userInfo);

/**
 * Listens to a given notification name on the queue (thread) which posts the
 * notification. It then calls the block parameter; if this block returns YES,
 * removes the observer. If the block returns NO, it keeps listening.
 *
 * @returns observer handle
 */
id _Nonnull fetchNotification(NSString* _Nonnull notificationName, notificationBlock _Nonnull block);

/** Creates a new NSError with a message. */
NSError* _Nonnull newError(NSString* _Nonnull msg);

/** Util method for creating a constraint that matches given attribute exactly between two views. */
NSLayoutConstraint* _Nonnull constrain(UIView* _Nonnull view1, UIView* _Nonnull view2, NSLayoutAttribute attr);

/** Util method for creating constraints for making all the edges of two views to match. */
NSArray<NSLayoutConstraint*>* _Nonnull constrainToMatch(UIView* _Nonnull view1, UIView* _Nonnull view2);

/** Returns the resource bundle containing the requested resource. */
NSBundle* _Nonnull findResourceBundle(void);

/** Loads a nib by the class name and asserts that the loaded instance is of the given class type. */
UIView* _Nonnull loadFromNib(Class _Nonnull class);

/** Asynchronously retrieves the site configuration from the server over HTTPS. */
void fetchSiteConfig(NSString* _Nonnull serverAddress, NSString* _Nonnull configurationKey, fetchSiteConfigCallbackBlock _Nonnull callbackBlock);

/** Looks up a MIME type for a file name. */
NSString* _Nonnull guessMIMETypeFromFileName(NSString* _Nonnull fileName);

/** Return a single pixel image with given color. */
UIImage* _Nonnull imageFrom(UIColor* _Nonnull color);

#endif /* NINUtils_h */
