//
//  NINClient.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 24/04/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChatSession.h"
#import "NINInitialViewController.h"
#import "NINUtils.h"
#import "NINSessionManager.h"
#import "NINChatSession+Internal.h"
#import "NINQueue.h"
#import "NINQueueViewController.h"

// Server addresses
static NSString* const kTestServerAddress = @"api.luupi.net";
static NSString* const kProductionServerAddress = @"api.ninchat.com";

// Image asset keys
NINImageAssetKey NINImageAssetKeyIconLoader = @"NINImageAssetKeyQueueViewProgressIndicator";
NINImageAssetKey NINImageAssetKeyChatWritingIndicator = @"NINImageAssetKeyChatWritingIndicator";
NINImageAssetKey NINImageAssetKeyChatBackground = @"NINImageAssetKeyChatBackground";
NINImageAssetKey NINImageAssetKeyChatCloseButton = @"NINImageAssetKeyChatCloseButton";
NINImageAssetKey NINImageAssetKeyIconChatCloseButton = @"NINImageAssetKeyIconChatCloseButton";
NINImageAssetKey NINImageAssetKeyChatBubbleLeft = @"NINImageAssetKeyChatBubbleLeft";
NINImageAssetKey NINImageAssetKeyChatBubbleLeftRepeated = @"NINImageAssetKeyChatBubbleLeftRepeated";
NINImageAssetKey NINImageAssetKeyChatBubbleRight = @"NINImageAssetKeyChatBubbleRight";
NINImageAssetKey NINImageAssetKeyChatBubbleRightRepeated = @"NINImageAssetKeyChatBubbleRightRepeated";
NINImageAssetKey NINImageAssetKeyIconRatingPositive = @"NINImageAssetKeyIconRatingPositive";
NINImageAssetKey NINImageAssetKeyIconRatingNeutral = @"NINImageAssetKeyIconRatingNeutral";
NINImageAssetKey NINImageAssetKeyIconRatingNegative = @"NINImageAssetKeyIconRatingNegative";
NINImageAssetKey NINImageAssetKeyChatAvatarRight = @"NINImageAssetKeyChatAvatarRight";
NINImageAssetKey NINImageAssetKeyChatAvatarLeft = @"NINImageAssetKeyChatAvatarLeft";
NINImageAssetKey NINImageAssetKeyChatPlayVideo = @"NINImageAssetKeyChatPlayVideo";
NINImageAssetKey NINImageAssetKeyIconTextareaCamera = @"NINImageAssetKeyIconTextareaCamera";
NINImageAssetKey NINImageAssetKeyIconTextareaAttachment = @"NINImageAssetKeyIconTextareaAttachment";
NINImageAssetKey NINImageAssetKeyTextareaSubmitButton = @"NINImageAssetKeyTextareaSubmitButton";
NINImageAssetKey NINImageAssetKeyIconTextareaSubmitButtonIcon = @"NINImageAssetKeyIconTextareaSubmitButtonIcon";
NINImageAssetKey NINImageAssetKeyIconVideoToggleFull = @"NINImageAssetKeyIconVideoToggleFull";
NINImageAssetKey NINImageAssetKeyIconVideoToggleNormal = @"NINImageAssetKeyIconVideoToggleNormal";
NINImageAssetKey NINImageAssetKeyIconVideoSoundOn = @"NINImageAssetKeyIconVideoSoundOn";
NINImageAssetKey NINImageAssetKeyIconVideoSoundOff = @"NINImageAssetKeyIconVideoSoundOff";
NINImageAssetKey NINImageAssetKeyIconVideoMicrophoneOn = @"NINImageAssetKeyIconVideoMicrophoneOn";
NINImageAssetKey NINImageAssetKeyIconVideoMicrophoneOff = @"NINImageAssetKeyIconVideoMicrophoneOff";
NINImageAssetKey NINImageAssetKeyIconVideoCameraOn = @"NINImageAssetKeyIconVideoCameraOn";
NINImageAssetKey NINImageAssetKeyIconVideoCameraOff = @"NINImageAssetKeyIconVideoCameraOff";
NINImageAssetKey NINImageAssetKeyIconVideoHangup = @"NINImageAssetKeyIconVideoHangup";
NINImageAssetKey NINImageAssetKeyPrimaryButton = @"NINImageAssetKeyPrimaryButton";
NINImageAssetKey NINImageAssetKeySecondaryButton = @"NINImageAssetKeySecondaryButton";
NINImageAssetKey NINImageAssetKeyIconDownload = @"NINImageAssetKeyIconDownload";

// Color asset keys
NINColorAssetKey NINColorAssetKeyButtonPrimaryText = @"NINColorAssetKeyButtonPrimaryText";
NINColorAssetKey NINColorAssetKeyButtonSecondaryText = @"NINColorAssetKeyButtonSecondaryText";
NINColorAssetKey NINColorAssetKeyInfoText = @"NINColorAssetKeyInfoText";
NINColorAssetKey NINColorAssetKeyChatName = @"NINColorAssetKeyChatName";
NINColorAssetKey NINColorAssetKeyChatTimestamp = @"NINColorAssetKeyChatTimestamp";
NINColorAssetKey NINColorAssetKeyChatBubbleLeftText = @"NINColorAssetKeyChatBubbleLeftText";
NINColorAssetKey NINColorAssetKeyChatBubbleRightText = @"NINColorAssetKeyChatBubbleRightText";
NINColorAssetKey NINColorAssetKeyTextareaText = @"NINColorAssetKeyTextareaText";
NINColorAssetKey NINColorAssetKeyTextareaSubmitText = @"NINColorAssetKeyTextareaSubmitText";
NINColorAssetKey NINColorAssetKeyChatBubbleLeftLink = @"NINColorAssetKeyChatBubbleLeftLink";
NINColorAssetKey NINColorAssetKeyChatBubbleRightLink = @"NINColorAssetKeyChatBubbleRightLink";
NINColorAssetKey NINColorAssetKeyModalText = @"NINColorAssetKeyModalText";
NINColorAssetKey NINColorAssetKeyModalBackground = @"NINColorAssetKeyModalBackground";
NINColorAssetKey NINColorAssetBackgroundTop = @"NINColorAssetBackgroundTop";
NINColorAssetKey NINColorAssetTextTop = @"NINColorAssetTextTop";
NINColorAssetKey NINColorAssetLink = @"NINColorAssetLink";
NINColorAssetKey NINColorAssetBackgroundBottom = @"NINColorAssetBackgroundBottom";
NINColorAssetKey NINColorAssetTextBottom = @"NINColorAssetTextBottom";
NINColorAssetKey NINColorAssetRatingPositiveText = @"NINColorAssetRatingPositiveText";
NINColorAssetKey NINColorAssetRatingNeutralText = @"NINColorAssetRatingNeutralText";
NINColorAssetKey NINColorAssetRatingNegativeText = @"NINColorAssetRatingNegativeText";

@interface NINChatSession ()

/** Session manager instance. */
@property (nonatomic, strong) NINSessionManager* sessionManager;

/** Configuration key; used to retrieve service configuration (site config) */
@property (nonatomic, strong) NSString* configKey;

/** Whether the SDK engine has been started ok */
@property (nonatomic, assign) BOOL started;

/** ID of the queue to join automatically. Nil to not join automatically to a queue. */
@property (nonatomic, strong) NSString* queueID;

/** Environments to use. */
@property (nonatomic, strong) NSArray<NSString*>* environments;

@end

@implementation NINChatSession

#pragma mark - Public API

-(void) setServerAddress:(NSString*)serverAddress {
    self.sessionManager.serverAddress = serverAddress;
}

-(NSString*) serverAddress {
    return self.sessionManager.serverAddress;
}

-(void) setSiteSecret:(NSString*)siteSecret {
    self.sessionManager.siteSecret = siteSecret;
}

-(NSString*) siteSecret {
    return self.sessionManager.siteSecret;
}

-(void) setAudienceMetadata:(NINLowLevelClientProps*)audienceMetadata {
    self.sessionManager.audienceMetadata = audienceMetadata;
}

-(NINLowLevelClientProps*) audienceMetadata {
    return self.sessionManager.audienceMetadata;
}

-(NINLowLevelClientSession*) session {
    NSCAssert(self.started, @"API has not been started");

    return self.sessionManager.session;
}

-(nonnull UIViewController*) viewControllerWithNavigationController:(BOOL)withNavigationController {
    NSCAssert([NSThread isMainThread], @"Must be called in main thread");

    if (!self.started) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"NINChat API has not been started; call -startWithCallback first"
                                     userInfo:nil];
    }

    NSBundle* bundle = findResourceBundle();
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Chat" bundle:bundle];

    // If a queue ID is specified, look that queue up and join it automatically
    if (self.queueID != nil) {
        // Find the queue object by its ID
        for (NINQueue* queue in self.sessionManager.queues) {
            if ([queue.queueID isEqualToString:self.queueID]) {
                // Load queue view controller directly
                NINQueueViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"NINQueueViewController"];
                NSCAssert([vc isKindOfClass:NINQueueViewController.class], @"Invalid NINQueueViewController");
                vc.sessionManager = self.sessionManager;
                vc.queueToJoin = queue;

                return vc;
            }
        }

        // Queue not found!
        [self sdklog:@"Queue with id '%@' not found!", self.queueID];
        return nil;
    }

    // Get the initial view controller for the storyboard
    UIViewController* vc = [storyboard instantiateInitialViewController];

    // Assert that the initial view controller from the Storyboard is a navigation controller
    UINavigationController* navigationController = (UINavigationController*)vc;
    NSCAssert([navigationController isKindOfClass:[UINavigationController class]], @"Storyboard initial view controller is not UINavigationController");

    // Find our own initial view controller
    NINInitialViewController* initialViewController = (NINInitialViewController*)navigationController.topViewController;
    NSCAssert([initialViewController isKindOfClass:[NINInitialViewController class]], @"Storyboard navigation controller's top view controller is not NINInitialViewController");
    initialViewController.sessionManager = self.sessionManager;
    
    if (withNavigationController) {
        return navigationController;
    } else {
        return initialViewController;
    }
}

// Performs these steps:
// 1. Fetches the site configuration over a REST call
// 2. Using that configuration, starts a new chat session
// 3. Retrieves the queues available for this realm (realm id from site configuration)
-(void) startWithCallback:(nonnull startCallbackBlock)callbackBlock {
    __weak typeof(self) weakSelf = self;

    if (self.sessionManager.serverAddress == nil) {
        // Use a default value for server address
#ifdef NIN_USE_TEST_SERVER
        self.sessionManager.serverAddress = kTestServerAddress;
#else
        self.sessionManager.serverAddress = kProductionServerAddress;
#endif
    }

    [self sdklog:@"Starting a chat session"];

    // Fetch the site configuration
    fetchSiteConfig(weakSelf.sessionManager.serverAddress, weakSelf.configKey, ^(NSDictionary* config, NSError* error) {
        NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
        NSCAssert(weakSelf != nil, @"This pointer should not be nil here.");

        if (error != nil) {
            callbackBlock(error);
            return;
        }

        NSLog(@"Got site config: %@", config);

        weakSelf.sessionManager.siteConfiguration = [NINSiteConfiguration siteConfigurationWith:config];
        weakSelf.sessionManager.siteConfiguration.environments = weakSelf.environments;

        // Open the chat session
        NSError* openSessionError = [weakSelf.sessionManager openSession:^(NSError *error) {
            NSCAssert([NSThread isMainThread], @"Must be called on the main thread");
            NSCAssert(weakSelf != nil, @"This pointer should not be nil here.");

            if (error != nil) {
                callbackBlock(error);
                return;
            }

            // Find our realm's queues
            NSArray<NSString*>* queueIds = [weakSelf.sessionManager.siteConfiguration valueForKey:@"audienceQueues"];
            
            if (queueIds != nil) {
                // If the queueID we've been initialized with isnt in the config's set of
                // audienceQueues, add it's ID to the list and we'll see if it exists
                [self sdklog:@"Adding my queueID %@", self.queueID];
                queueIds = [queueIds arrayByAddingObject:self.queueID];
            }
            
            // Potentially passing a nil queueIds here is intended
            [weakSelf.sessionManager listQueuesWithIds:queueIds completion:^(NSError* error) {
                NSCAssert([NSThread isMainThread], @"Must be called on the main thread");

                if (error == nil) {
                    weakSelf.started = YES;
                }
                callbackBlock(error);
            }];
        }];

        if (openSessionError != nil) {
            callbackBlock(error);
        }
    });
}

-(id _Nonnull) initWithConfigKey:(NSString* _Nonnull)configKey queueID:(NSString* _Nullable)queueID {
    return [self initWithConfigKey:configKey queueID:queueID environments:nil];
}

-(id _Nonnull) initWithConfigKey:(NSString* _Nonnull)configKey queueID:(NSString* _Nullable)queueID environments:(NSArray<NSString*>* _Nullable)environments{
    self = [super init];
    
    if (self != nil) {
        self.sessionManager = [NINSessionManager new];
        self.sessionManager.ninchatSession = self;
        self.configKey = configKey;
        self.queueID = queueID;
        self.environments = environments;
        self.started = NO;
    }
    
    return self;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

// Prevent calling the default initializer
-(id) init {
    self = [super init];

    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@", NSStringFromClass(self.class)]
                                 userInfo:nil];
    return nil;
}

@end
