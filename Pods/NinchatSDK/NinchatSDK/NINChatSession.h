//
//  NINClient.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

@import NinchatLowLevelClient;

#import "NINPublicTypes.h"

// Forward declarations
@class NINChatSession;

/**
 * Delegate protocol for NINChatSession class. All the methods are called on
 * the main thread.
 */
@protocol NINChatSessionDelegate <NSObject>

/**
 * Implemeent this if you want to receive debug/error logging from the SDK.
 *
 * Optional method.
 */
@optional
-(void) ninchat:(NINChatSession*_Nonnull)session didOutputSDKLog:(NSString* _Nonnull)message;

/**
 * Exposes the low-level events. See the Ninchat API specification for more info.
 *
 * Optional method.
 */
@optional
-(void) ninchat:(NINChatSession*_Nonnull)session onLowLevelEvent:(NINLowLevelClientProps*_Nonnull)params payload:(NINLowLevelClientPayload*_Nonnull)payload lastReply:(BOOL)lastReply;

/**
 * This method allows the SDK user to override image assets used in the
 * SDK UI. If the implementation does not wish to override a specific asset, nil should
 * be returned for that key.
 *
 * For available asset key constants, see documentation.
 *
 * Optional method.
 */
@optional
-(UIImage* _Nullable) ninchat:(NINChatSession*_Nonnull)session overrideImageAssetForKey:(NINImageAssetKey _Nonnull)assetKey;

/**
 * This method allows the SDK user to override color assets used in the SDK UI.
 * If the implementation does not wish to override a specific asset, nil should
 * be returned for that key.
 *
 * For available asset key constants, see documentation.
 *
 * Optional method.
 */
@optional
-(UIColor* _Nullable) ninchat:(NINChatSession*_Nonnull)session overrideColorAssetForKey:(NINColorAssetKey _Nonnull)assetKey;

/**
 * Indicates that the Ninchat SDK UI has completed its chat. and would like
 * to be closed. The API caller should remove the Ninchat SDK UI from
 * its view hierarchy.
 */
-(void) ninchatDidEndSession:(NINChatSession* _Nonnull)ninchat;

@end

/**
 * Ninchat chat session. Instantiate with the dedicated initializer
 * -initWithConfigurationKey:siteSecret:.
 *
 * Create a new session for each chat session; UI component(s) returned by
 * the chat session are not recycleable either.
 */
@interface NINChatSession : NSObject

/** Exposes the low-level chat session interface. Only available after startWithCallback: has been called. */
@property (nonatomic, strong, readonly) NINLowLevelClientSession* _Nonnull session;

/**
 * Delegate object for receiving asynchronous callbacks from the SDK.
 */
@property (nonatomic, weak, nullable) id<NINChatSessionDelegate> delegate;

/** Set this prior to calling startWithCallback: if you need to supply a site secret. */
@property (nonatomic, strong) NSString* _Nullable serverAddress;

/** Set this prior to calling startWithCallback: if you need to override server address. */
@property (nonatomic, strong) NSString* _Nullable siteSecret;

/** Value to be passed as audience_metadata parameter for request_audience calls. */
@property (nonatomic, strong) NINLowLevelClientProps* _Nullable audienceMetadata;

/**
 * Initializes the API using default environment.
 *
 * @param configKey configuration key; this decides the chat realm
 * @param queueID ID of the queue to join automatically. Nil to not join automatically to a queue.
 * @return new API facade instance
 */
-(id _Nonnull) initWithConfigKey:(NSString* _Nonnull)configKey queueID:(NSString* _Nullable)queueID;

/**
 * Initializes the API.
 *
 * @param configKey configuration key; this decides the chat realm
 * @param queueID ID of the queue to join automatically. Nil to not join automatically to a queue.
 * @param environments site config environments to use instead of default
 * @return new API facade instance
 */
-(id _Nonnull) initWithConfigKey:(NSString* _Nonnull)configKey queueID:(NSString* _Nullable)queueID environments:(NSArray<NSString*>* _Nullable)environments;

/**
 * Starts the API engine. Must be called before other API methods. The caller
 * must wait for the callback block to be called without errors.
 */
-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock;

/**
 * Returns the view controller for the Ninchat UI.
 */
-(nonnull UIViewController*) viewControllerWithNavigationController:(BOOL)withNavigationController;

@end
