//
//  SessionManager.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@import NinchatLowLevelClient;

#import "NINPublicTypes.h"
#import "NINPrivateTypes.h"
#import "NINSiteConfiguration.h"
#import "NINChatSession+Internal.h" // To provide log: method
#import "NINChatMessage.h"

@class NINQueue;
@class NINTextMessage;
@class NINChatSession;
@class NINFileInfo;

typedef void (^getFileInfoCallback)(NSError* _Nullable error, NSDictionary* _Nullable fileInfo);

/** Notification that indicates the current channel was closed. */
extern NSString* _Nonnull const kNINChannelClosedNotification;

/**
 * Notification name for channel messages notification. Userinfo param 'newMessage'
 * contains a ChannelMessage* object for when there is a new message; that
 * message is inserted at the top of the list at index 0.
 * When a message is removed, 'removedMessageAtIndex' contains a NSNumber
 * representing NSInteger describing the index of the removed message.
 */
extern NSString* _Nonnull const kChannelMessageNotification;

/**
 * Notification that indicates a user is currently typing into the chat.
 * Userinfo contains user_id to indicate which user. These are not sent
 * for the SDK user's own user id.
 */
//extern NSString* _Nonnull const kNINUserIsTypingNotification;

/** Notification that indicates the user joining a queue (audience_enqueued event). */
extern NSString* _Nonnull const kNINQueuedNotification;

/**
 * Notification that indicates a WebRTC signaling message was received.
 * Userinfo 'messageType' contains a kNINMessageTypeWebRTC* value, 'payload'
 * contains the message payload.
 */
extern NSString* _Nonnull const kNINWebRTCSignalNotification;

/** Message type for WebRTC signaling: 'ICE candidate' */
extern NSString* _Nonnull const kNINMessageTypeWebRTCIceCandidate;

/** Message type for WebRTC signaling: 'answer'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCAnswer;

/** Message type for WebRTC signaling: 'offer'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCOffer;

/** Message type for WebRTC signaling: 'call'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCCall;

/** Message type for WebRTC signaling: 'pick up'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCPickup;

/** Message type for WebRTC signaling: 'hang up'. */
extern NSString* _Nonnull const kNINMessageTypeWebRTCHangup;

/**
 This class takes care of the chat session and all related state.
 */
@interface NINSessionManager : NSObject

/** Weak reference to the session object that created this session manager. */
@property (nonatomic, weak) NINChatSession* _Nullable ninchatSession;

/** The server address as host[:port]. */
@property (nonatomic, strong) NSString* _Nullable serverAddress;

/** Low-level chat session reference. */
@property (nonatomic, strong, readonly) NINLowLevelClientSession* _Nonnull session;

/** Site secret; used to authenticate to eg. test servers. */
@property (nonatomic, strong) NSString* _Nullable siteSecret; 

/** Site configuration. */
@property (nonatomic, strong) NINSiteConfiguration* _Nonnull siteConfiguration;

/** List of available queues for the realm_id. */
@property (nonatomic, strong) NSArray<NINQueue*>* _Nonnull queues;

/** List of Audience queues. These are the queues the user gets to pick from in the UI. */
@property (nonatomic, strong) NSArray<NINQueue*>* _Nonnull audienceQueues;

/** Whether or not this session is connected. */
@property (nonatomic, assign, readonly) BOOL connected;

/**
 * Chronological list of messages on the current channel. The list is ordered by the message
 * timestamp in decending order (most recent first).
 */
@property (nonatomic, strong, readonly) NSArray<id<NINChatMessage>>* _Nonnull chatMessages;

/** Value to be passed as audience_metadata parameter for request_audience calls. */
@property (nonatomic, strong) NINLowLevelClientProps* _Nullable audienceMetadata;

/** Opens the session with an asynchronous completion callback. */
-(NSError*_Nonnull) openSession:(startCallbackBlock _Nonnull)callbackBlock;

/** List queues with specified ids for this realm, all available ones if queueIds is nil. */
-(void) listQueuesWithIds:(NSArray<NSString*>* _Nullable)queueIds completion:(callbackWithErrorBlock _Nonnull)completion;

/** Joins a chat queue. */
-(void) joinQueueWithId:(NSString* _Nonnull)queueId progress:(queueProgressCallback _Nonnull)progress channelJoined:(emptyBlock _Nonnull)channelJoined;

/** Leaves the current queue. */
-(void) leaveCurrentQueueWithCompletionCallback:(callbackWithErrorBlock _Nonnull)completion;

/** Runs ICE (Interactive Connectivity Establishment) for WebRTC connection negotiations. */
-(void) beginICEWithCompletionCallback:(beginICECallbackBlock _Nonnull)completion;

/** Sends a message to the activa channel. Active channel must exist. */
-(int64_t) sendMessageWithMessageType:(NSString* _Nonnull)messageType payloadDict:(NSDictionary* _Nonnull)payloadDict completion:(callbackWithErrorBlock _Nonnull)completion;

/** Sends chat message to the active chat channel. */
-(void) sendTextMessage:(NSString* _Nonnull)message completion:(callbackWithErrorBlock _Nonnull)completion;

/** Sends a ui/action response to the current channel. */
-(void) sendUIActionMessage:(NSDictionary* _Nonnull)composeMessageDict completion:(callbackWithErrorBlock _Nonnull)completion;

/** Sends a file to the chat. */
-(void) sendFileWithFilename:(NSString*_Nonnull)fileName withData:(NSData*_Nonnull)data completion:(callbackWithErrorBlock _Nonnull)completion;

/** Describe a file by its ID. */
-(void) describeFile:(NSString* _Nonnull)fileID completion:(getFileInfoCallback _Nonnull)completion;

/** Indicate whether or not the user is currently typing into the chat. */
-(void) setIsWriting:(BOOL)isWriting completion:(callbackWithErrorBlock _Nonnull)completion;

/** Load channel history. */
-(void) loadHistoryWithCompletion:(callbackWithErrorBlock _Nonnull)completion;
    
/** Closes the chat by shutting down the session. Triggers the API delegate method -ninchatDidEndChatSession:. */
-(void) closeChat;

/** (Optionally) sends ratings and finishes the current chat from our end. */
-(void) finishChat:(NSNumber* _Nullable)rating;

/**
 * Get a formatted translation from the site configuration.
 * @param formatParams contains format param mappings key -> value
 */
-(NSString*_Nullable) translation:(NSString*_Nonnull)keyName formatParams:(NSDictionary<NSString*,NSString*>*_Nullable)formatParams;

@end
