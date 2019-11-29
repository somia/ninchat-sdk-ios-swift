//
//  SessionManager.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 08/07/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINSessionManager.h"
#import "NINUtils.h"
#import "NINQueue.h"
#import "NINChatSession.h"
#import "NINChatMessage.h"
#import "NINChannelMessage.h"
#import "NINTextMessage.h"
#import "NINUIComposeMessage.h"
#import "NINChatMetaMessage.h"
#import "NINUserTypingMessage.h"
#import "NINChannelUser.h"
#import "NINPrivateTypes.h"
#import "NINClientPropsParser.h"
#import "NINWebRTCServerInfo.h"
#import "NINWebRTCClient.h"
#import "NINChatSession+Internal.h"
#import "NINFileInfo.h"
#import "NINToast.h"
#import "NINMessageThrottler.h"

// UI texts
static NSString* const kConversationStartedText = @"Audience in queue {{queue}} accepted.";
static NSString* const kConversationEndedText = @"Conversation ended";
static NSString* const kCloseChatButtonText = @"Close chat";

/** Notification name for handling asynchronous completions for actions. */
static NSString* const kActionNotification = @"ninchatsdk.ActionNotification";

/** Notification name for channel_joined event. */
static NSString* const kChannelJoinedNotification = @"ninchatsdk.ChannelJoinedNotification";

/** Notification name for audience_enqueued event. */
NSString* const kNINQueuedNotification = @"ninchatsdk.QueuedNotification";

// Notification strings
NSString* const kChannelMessageNotification = @"ninchatsdk.ChannelMessageNotification";
NSString* const kNINWebRTCSignalNotification = @"ninchatsdk.NWebRTCSignalNotification";
NSString* const kNINChannelClosedNotification = @"ninchatsdk.ChannelClosedNotification";

// WebRTC related message types
NSString* _Nonnull const kNINMessageTypeWebRTCIceCandidate = @"ninchat.com/rtc/ice-candidate";
NSString* _Nonnull const kNINMessageTypeWebRTCAnswer = @"ninchat.com/rtc/answer";
NSString* _Nonnull const kNINMessageTypeWebRTCOffer = @"ninchat.com/rtc/offer";
NSString* _Nonnull const kNINMessageTypeWebRTCCall = @"ninchat.com/rtc/call";
NSString* _Nonnull const kNINMessageTypeWebRTCPickup = @"ninchat.com/rtc/pick-up";
NSString* _Nonnull const kNINMessageTypeWebRTCHangup = @"ninchat.com/rtc/hang-up";

/**
 * This class is used to work around circular reference memory leaks caused by the gomobile bind.
 * It cannot hold a reference to 'proxy objects' ie. the ClientSession.
 */
@interface SessionCallbackHandler : NSObject <NINLowLevelClientSessionEventHandler, NINLowLevelClientEventHandler, NINLowLevelClientCloseHandler, NINLowLevelClientLogHandler, NINLowLevelClientConnStateHandler>

@property (nonatomic, weak) NINSessionManager* sessionManager;

+(instancetype) handlerWithSessionManager:(NINSessionManager*)sessionManager;

@end

/**
 This implementation is written against the following API specification:

 https://github.com/ninchat/ninchat-api/blob/v2/api.md
 */
@interface NINSessionManager () {
    /** Mutable queue list. */
    NSMutableArray<NINQueue*>* _queues;

    /** Mutable audience queue list. */
    NSMutableArray<NINQueue*>* _audienceQueues;

    /** Mutable channel messages list. */
    NSMutableArray<id<NINChatMessage>>* _chatMessages;

    /** Channel user map; ID -> NINChannelUser. */
    NSMutableDictionary<NSString*, NINChannelUser*>* _channelUsers;
    
    /** Message throttler that manages message order by their message_id. */
    NINMessageThrottler* _messageThrottler;
}

/** Realm ID to use. */
@property (nonatomic, strong) NSString* _Nonnull realmId;

/** Low-level chat session reference. */
@property (nonatomic, strong) NINLowLevelClientSession* session;

/** Callback 'adapter' for the low-level library. */
@property (nonatomic, strong) SessionCallbackHandler* sessionCallbackHandler;
/** My user's user ID. */
@property (nonatomic, strong) NSString* myUserID;

/** Current queue id. Nil if not currently in queue. */
@property (nonatomic, strong) NSString* currentQueueID;

/** Currently active channel id - or nil if no active channel. */
@property (nonatomic, strong) NSString* currentChannelID;

/** "Active" channel id during transfer process - or nil if not currently transferring. */
@property (nonatomic, strong) NSString* backgroundChannelID;

/** Channel join observer; while in queue. */
@property (nonatomic, strong) id<NSObject> channelJoinObserver;

/** Queue progress observer. */
@property (nonatomic, strong) id<NSObject> queueProgressObserver;

@end

// Waits for a matching action notification and calls the specified callback block,
// then unregisters the notification observer.
void connectCallbackToActionCompletion(int64_t actionId, callbackWithErrorBlock completion) {
    fetchNotification(kActionNotification, ^(NSNotification* note) {
        NSNumber* eventActionId = note.userInfo[@"action_id"];
        NSError* error = note.userInfo[@"error"];

        if (eventActionId.longValue == actionId) {
            if (completion != nil) {
                completion(error);
            }

            return YES;
        }

        return NO;
    });
}

@implementation NINSessionManager

#pragma mark - Private methods

// Returns a queue by its id
-(NINQueue* _Nullable) queueForId:(NSString*)queueID {
    for (NINQueue* q in _queues) {
        if ([q.queueID isEqualToString:queueID]) {
            return q;
        }
    }

    return nil;
}

-(void) realmQueuesFound:(NINLowLevelClientProps*)params {
    NSError* error;

    // Clear existing queue list
    [self.ninchatSession sdklog:@"Realm queues found - flushing list of previously available queues."];
    [_queues removeAllObjects];

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    NINLowLevelClientProps* queues = [params getObject:@"realm_queues" error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }

    NINClientPropsParser* queuesParser = [NINClientPropsParser new];
    [queues accept:queuesParser error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }

    for (NSString* queueId in queuesParser.properties.allKeys) {
        NINLowLevelClientProps* queueProps = [queues getObject:queueId error:&error];
        if (error != nil) {
            postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
            return;
        }

        NINLowLevelClientProps* queueAttrs = [queueProps getObject:@"queue_attrs" error:&error];
        if (error != nil) {
            postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
            return;
        }

        NSString* queueName = [queueAttrs getString:@"name" error:&error];
        if (error != nil) {
            postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
            return;
        }

        [_queues addObject:[NINQueue queueWithId:queueId andName:queueName]];
    }

    // Form the list of audience queues; if audienceQueues is specified in siteConfig, we use those;
    // if not, we use the complete list of queues.
    NSArray* audienceQueueIDs = [self.siteConfiguration valueForKey:@"audienceQueues"];
    if (audienceQueueIDs == nil) {
        _audienceQueues = [NSMutableArray arrayWithArray:_queues];
    } else {
        _audienceQueues = [NSMutableArray arrayWithCapacity:audienceQueueIDs.count];
        for (NSString* queueID in audienceQueueIDs) {
            NINQueue* q = [self queueForId:queueID];
            if (q != nil) {
                [_audienceQueues addObject:q];
            }
        }
    }

    postNotification(kActionNotification, @{@"action_id": @(actionId)});
}

// https://github.com/ninchat/ninchat-api/blob/v2/api.md#audience_enqueued
// https://github.com/ninchat/ninchat-api/blob/v2/api.md#queue_updated
-(void) queueUpdated:(NSString*)eventType params:(NINLowLevelClientProps*)params {
    NSError* error;

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    NSString* queueId = [params getString:@"queue_id" error:&error];
    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }
    
    long position;
    [params getInt:@"queue_position" val:&position error:&error];
    
    if ([eventType isEqualToString:@"audience_enqueued"]) {
        NSCAssert(self.currentQueueID == nil, @"Already have current queue");
        self.currentQueueID = queueId;
        if (error == nil) {
            postNotification(kNINQueuedNotification, @{@"event": eventType, @"action_id": @(actionId), @"queue_id": queueId, @"queue_position": @(position)});
        } else {
            postNotification(kNINQueuedNotification, @{@"event": eventType, @"action_id": @(actionId), @"queue_id": queueId});
        }
    }

    if (error != nil) {
        postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": error});
        return;
    }

    if ((actionId != 0) || [eventType isEqualToString:@"queue_updated"]) {
        postNotification(kActionNotification, @{@"event": eventType, @"action_id": @(actionId), @"queue_position": @(position), @"queue_id": queueId});
    }
}

-(NINChannelUser*) parseUserAttrs:(NINLowLevelClientProps*)userAttrs userID:(NSString*)userID {
    NSError* error;

    NSString* iconURL = [userAttrs getString:@"iconurl" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get iconurl: %@", error);
        return nil;
    }

    NSString* displayName = [userAttrs getString:@"name" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get name: %@", error);
        return nil;
    }

    NSString* realName = [userAttrs getString:@"realname" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get realname: %@", error);
        return nil;
    }

    BOOL guest = NO;
    [userAttrs getBool:@"guest" val:&guest error:&error];
    if (error != nil) {
        NSLog(@"Failed to get guest: %@", error);
        return nil;
    }

    return [NINChannelUser userWithID:userID realName:realName displayName:displayName iconURL:iconURL guest:guest];
}

-(void) userUpdated:(NINLowLevelClientProps*)params {
    NSError* error;

    NSCAssert(self.currentChannelID != nil, @"No active channel");

    NSString* userID = [params getString:@"user_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get user_id: %@", error);
        return;
    }

    NINLowLevelClientProps* userAttrs = [params getObject:@"user_attrs" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get user_attrs: %@", error);
        return;
    }

    _channelUsers[userID] = [self parseUserAttrs:userAttrs userID:userID];
}

-(void) fileFound:(NINLowLevelClientProps*)params {
    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

//    NSString* fileID = [params getString:@"file_id" error:&error];
//    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* url = [params getString:@"file_url" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    double expiry;
    [params getFloat:@"url_expiry" val:&expiry error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");
    NSDate* urlExpiry = [NSDate dateWithTimeIntervalSince1970:expiry];

    NINLowLevelClientProps* fileAttributes = [params getObject:@"file_attrs" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

//    NSString* mimeType = [fileAttributes getString:@"type" error:&error];
//    NSCAssert(error == nil, @"Failed to get attribute");
//
//    NSString* name = [fileAttributes getString:@"name" error:&error];
//    NSCAssert(error == nil, @"Failed to get attribute");
//
//    long size;
//    [fileAttributes getInt:@"size" val:&size error:&error];
//    NSCAssert(error == nil, @"Failed to get attribute");

    NINLowLevelClientProps* thumbnail = [fileAttributes getObject:@"thumbnail" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    CGFloat aspectRatio = 1.0;

    // If thumbnail object is present, use its dimensions to calculate image aspect ratio
    if (thumbnail != nil) {
        long width;
        [thumbnail getInt:@"width" val:&width error:&error];
        NSCAssert(error == nil, @"Failed to get attribute");

        long height;
        [thumbnail getInt:@"height" val:&height error:&error];
        NSCAssert(error == nil, @"Failed to get attribute");

        aspectRatio = (CGFloat)width / (CGFloat)height;
    }

    //TODO handle other file types too?
//    NINFileInfo* fileInfo = [NINFileInfo imageFileInfoWithID:fileID name:name mimeType:mimeType size:size url:url urlExpiry:urlExpiry aspectRatio:aspectRatio];
    NSDictionary* fileInfo = @{@"aspectRatio": @(aspectRatio), @"url": url, @"urlExpiry": urlExpiry};

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"fileInfo": fileInfo});
}

-(void) userDeleted:(NINLowLevelClientProps*)params {
    NSError* error;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* userId = [params getString:@"user_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");
    if ([userId isEqualToString:self.myUserID]) {
        [self.ninchatSession sdklog:@"Current user deleted."];
    }

    postNotification(kActionNotification, @{@"action_id": @(actionId)});
}

-(void) channelJoined:(NINLowLevelClientProps*)params {
    NSError* error = nil;

    NSCAssert(self.currentQueueID != nil, @"No current queue");
    NSCAssert(self.currentChannelID == nil, @"Already have active channel");

    NSString* channelId = [params getString:@"channel_id" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get channel id: %@", error);
        return;
    }
    NSCAssert(channelId != nil, @"Channel ID must exist");

    [self.ninchatSession sdklog:@"Joined channel ID: %@", channelId];

    // Set the currently active channel
    self.currentChannelID = channelId;
    self.backgroundChannelID = nil;

    // Get the queue we are joining
    NINQueue* queue = [self queueForId:self.currentQueueID];
    NSString* queueName = @"";
    if (queue != nil && queue.name != nil) {
        queueName = queue.name;
    }
    
    // We are no longer in the queue; clear the queue reference
    self.currentQueueID = nil;

    // Clear current list of messages and users
    [_chatMessages removeAllObjects];
    [_channelUsers removeAllObjects];

    // Insert a meta message about the conversation start
    [self addNewChatMessage:[NINChatMetaMessage messageWithText:[self translation:kConversationStartedText formatParams:@{@"queue": queueName}] timestamp:[NSDate date] closeChatButtonTitle:nil]];

    // Extract the channel members' data
    NINLowLevelClientProps* members = [params getObject:@"channel_members" error:&error];
    if (error != nil) {
        NSLog(@"Failed to get channel_members: %@", error);
        return;
    }

    NINClientPropsParser* memberParser = [NINClientPropsParser new];
    [members accept:memberParser error:&error];
    if (error != nil) {
        NSLog(@"Failed to traverse members array: %@", error);
        return;
    }

    for (NSString* userID in memberParser.properties.allKeys) {
        NINLowLevelClientProps* memberAttrs = memberParser.properties[userID];
        NINLowLevelClientProps* userAttrs = [memberAttrs getObject:@"user_attrs" error:&error];
        if (error != nil) {
            NSLog(@"Failed to get user_attrs: %@", error);
            continue;
        }

        _channelUsers[userID] = [self parseUserAttrs:userAttrs userID:userID];
    }

    // Signal channel join event to the asynchronous listener
    postNotification(kChannelJoinedNotification, @{});
}

-(void) channelParted:(NINLowLevelClientProps*)params {
    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* channelID = [params getString:@"channel_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"channel_id": channelID});
}

-(void) channelUpdated:(NINLowLevelClientProps*)params {
    NSError* error;

    NSCAssert(self.currentChannelID != nil || self.backgroundChannelID != nil, @"No active channel");

    NSString* channelId = [params getString:@"channel_id" error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel_id: %@", error);
        return;
    }

    if (![channelId isEqualToString:self.currentChannelID]
        && ![channelId isEqualToString:self.backgroundChannelID]) {
        NSLog(@"Got channel_updated for wrong channel '%@'", channelId);
        return;
    }

    NINLowLevelClientProps* channelAttrs = [params getObject:@"channel_attrs" error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel attrs: %@", error);
        return;
    }

    BOOL closed;
    [channelAttrs getBool:@"closed" val:&closed error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel attr 'closed': %@", error);
        return;
    }

    BOOL suspended;
    [channelAttrs getBool:@"suspended" val:&suspended error:&error];
    if (error != nil) {
        NSLog(@"Could not get channel attr 'suspended': %@", error);
        return;
    }

    if (closed || suspended) {
        // Add a meta message about the conversation having ended
        NSString* text = [self translation:kConversationEndedText formatParams:nil];
        NSString* closeButtonTitle = [self translation:kCloseChatButtonText formatParams:nil];
        [self addNewChatMessage:[NINChatMetaMessage messageWithText:text timestamp:[NSDate date] closeChatButtonTitle:closeButtonTitle]];

        postNotification(kNINChannelClosedNotification, @{});
    }
}

// Processes the response to the WebRTC connectivity ICE query
-(void) iceBegun:(NINLowLevelClientProps*)params {
    NSError* error = nil;
    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    // Parse the STUN server list
    NINLowLevelClientObjects* stunServers = [params getObjectArray:@"stun_servers" error:&error];
    if (error != nil) {
        NSLog(@"Could not get stun_servers: %@", error);
        return;
    }
    NSMutableArray<NINWebRTCServerInfo*>* stunServerArray = [NSMutableArray array];
    for (int i = 0; i < stunServers.length; i++) {
        NINLowLevelClientProps* serverProps = [stunServers get:i];
        NINLowLevelClientStrings* urls = [serverProps getStringArray:@"urls" error:&error];
        if (error != nil) {
            NSLog(@"Could not get stun_servers.urls: %@", error);
            return;
        }
        for (int j = 0; j < urls.length; j++) {
            [stunServerArray addObject:[NINWebRTCServerInfo serverWithURL:[urls get:j] username:nil credential:nil]];
        }
    }

    // Parse the TURN server list
    NINLowLevelClientObjects* turnServers = [params getObjectArray:@"turn_servers" error:&error];
    if (error != nil) {
        NSLog(@"Could not get turn_servers: %@", error);
        return;
    }
    NSMutableArray<NINWebRTCServerInfo*>* turnServerArray = [NSMutableArray array];
    for (int i = 0; i < turnServers.length; i++) {
        NINLowLevelClientProps* serverProps = [turnServers get:i];

        NSString* username = [serverProps getString:@"username" error:&error];
        if (error != nil) {
            NSLog(@"Could not get turn_servers.username: %@", error);
            return;
        }

        NSString* credential = [serverProps getString:@"credential" error:&error];
        if (error != nil) {
            NSLog(@"Could not get turn_servers.credential: %@", error);
            return;
        }

        NINLowLevelClientStrings* urls = [serverProps getStringArray:@"urls" error:&error];
        if (error != nil) {
            NSLog(@"Could not get turn_servers.urls: %@", error);
            return;
        }
        for (int j = 0; j < urls.length; j++) {
            [turnServerArray addObject:[NINWebRTCServerInfo serverWithURL:[urls get:j] username:username credential:credential]];
        }
    }

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"stunServers": stunServerArray, @"turnServers": turnServerArray});
}

// Deletes the current user.
-(void) deleteCurrentUserWithCompletion:(callbackWithErrorBlock)completion {
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"delete_user"];

    NSError* error = nil;
    int64_t actionId;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error deleting the user: %@", error);
        return;
    }

    connectCallbackToActionCompletion(actionId, completion);
}

// Asynchronously retrieves file info
-(void) describeFile:(NSString*)fileID completion:(getFileInfoCallback)completion {
    // Fetch the file info, including the (temporary) download url for the file
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"describe_file"];
    [params setString:@"file_id" val:fileID];

    NSError* error = nil;
    int64_t actionId;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error getting file info: %@", error);
        completion(error, nil);
        return;
    }

    fetchNotification(kActionNotification, ^(NSNotification* note) {
        NSNumber* eventActionId = note.userInfo[@"action_id"];
        NSError* error = note.userInfo[@"error"];

        if (eventActionId.longValue == actionId) {
            completion(error, note.userInfo[@"fileInfo"]);
            return YES;
        }

        return NO;
    });
}

-(void) addNewChatMessage:(id<NINChatMessage>)message {
    NSCAssert([NSThread isMainThread], @"Must only be called on the main thread.");
    
    if ([message conformsToProtocol:@protocol(NINChannelMessage)]) {
        // Check if the previous (normal) message was sent by the same user, ie. is the
        // message part of a series
        NSObject<NINChannelMessage>* channelMessage = (NSObject<NINChannelMessage>*)message;
        
        // Guard against the same message getting added multiple times
        // should only happen if the client makes extraneous load_history calls elsewhere
        for (id<NINChatMessage> oldMessage in _chatMessages) {
            if (![oldMessage conformsToProtocol:@protocol(NINChannelMessage)]) {
                continue;
            }
            if ([channelMessage.messageID isEqualToString:((NSObject<NINChannelMessage>*)oldMessage).messageID]) {
                NSLog(@"Attempted to add an already existing message with id %@", channelMessage.messageID);
                return;
            }
        }

        channelMessage.series = NO;

        // Find the previous channel message
        NSObject<NINChannelMessage>* prevMsg = nil;
        for (NSInteger i = 0; i < _chatMessages.count; i++) {
            NSObject<NINChannelMessage>* msg = (NSObject<NINChannelMessage>*)_chatMessages[i];
            if ([msg isKindOfClass:NINTextMessage.class]) {
                prevMsg = msg;
                break;
            }
        }

        if (prevMsg != nil) {
            channelMessage.series = [prevMsg.sender.userID isEqualToString:channelMessage.sender.userID];
        }
    }
    
    [_chatMessages insertObject:message atIndex:0];
    [_chatMessages sortUsingComparator:^NSComparisonResult(id<NINChatMessage> _Nonnull msg1, id<NINChatMessage> _Nonnull msg2) {
        return [msg1.timestamp compare:msg2.timestamp] == NSOrderedAscending;
    }];

    postNotification(kChannelMessageNotification, @{@"action":@"insert", @"index":@([_chatMessages indexOfObject:message])});
}

-(void) removeChatMessageAtIndex:(NSInteger)index {
    [_chatMessages removeObjectAtIndex:index];
    postNotification(kChannelMessageNotification, @{@"action":@"remove", @"index":@(index)});
}

-(void) handleInboundChatMessageWithPayload:(NINLowLevelClientPayload*)payload messageID:(NSString*)messageID messageUser:(NINChannelUser*)messageUser messageTime:(CGFloat)messageTime actionId:(long)actionId {

    NSError* error = nil;

    for (int i = 0; i < payload.length; i++) {
        NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }

        NSLog(@"Received Chat message with payload: %@", payloadDict);

        BOOL hasAttachment = NO;
        NSArray* fileObjectsList = payloadDict[@"files"];
        if ((fileObjectsList != nil) && [fileObjectsList isKindOfClass:NSArray.class] && (fileObjectsList.count > 0)) {
            // Use the first object in the list
            NSDictionary* fileObject = fileObjectsList.firstObject;

            NSString* filename = fileObject[@"file_attrs"][@"name"];
            NSString* fileMediaType = fileObject[@"file_attrs"][@"type"];
            NSInteger fileSize = [fileObject[@"file_attrs"][@"size"] integerValue];

            if (fileMediaType == nil) {
                NSLog(@"No MIME type in file attributes; have to guess it.");
                fileMediaType = guessMIMETypeFromFileName(filename);
            }

            [self.ninchatSession sdklog:@"Got file with MIME type: '%@'", fileMediaType];

            // Only process certain files at this point
            if ([fileMediaType hasPrefix:@"image/"] || [fileMediaType hasPrefix:@"video/"] ||[fileMediaType isEqualToString:@"application/pdf"]) {

                hasAttachment = YES;
                __weak typeof(self) weakSelf = self;

                NINFileInfo* fileInfo = [NINFileInfo fileWithSessionManager:self fileID:fileObject[@"file_id"] name:filename mimeType:fileMediaType size:fileSize];

                [fileInfo updateInfoWithCompletionCallback:^(NSError * _Nullable error, BOOL didNetworkRefresh) {
                    if (error != nil) {
                        [NINToast showWithErrorMessage:@"Failed to update file info" callback:nil];
                    } else {
                        NINTextMessage* msg = [NINTextMessage messageWithID:messageID textContent:nil sender:messageUser timestamp:[NSDate dateWithTimeIntervalSince1970:messageTime]  mine:[messageUser.userID isEqualToString:self.myUserID] attachment:fileInfo];
                        [weakSelf addNewChatMessage:msg];
                    }
                }];
            }
        }

        NSString* text = payloadDict[@"text"];

        // Only allocate a new message now if there is text and no attachment
        if (!hasAttachment && (text.length > 0)) {
            NINTextMessage* msg = [NINTextMessage messageWithID:messageID textContent:text sender:messageUser timestamp:[NSDate dateWithTimeIntervalSince1970:messageTime] mine:[messageUser.userID isEqualToString:self.myUserID] attachment:nil];
            [self addNewChatMessage:msg];
        }
    }
}

-(void) handleChannelMessageWithPayload:(NINLowLevelClientPayload*)payload messageID:(NSString*)messageID messageUser:(NINChannelUser*)messageUser messageTime:(CGFloat)messageTime actionId:(long)actionId {
    
    for (int i = 0; i < payload.length; i++) {
        // not sure why the resulting dictionary here is wrapped in an array but let's roll with it for now at least
        NSError* error = nil;
        NSArray* payloadArray = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil && payloadArray.count > 1) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }
        
        NSLog(@"Received a Channel message with payload: %@", payloadArray);
    }
}

-(void) handleInboundComposeMessageWithPayload:(NINLowLevelClientPayload*)payload messageID:(NSString*)messageID messageUser:(NINChannelUser*)messageUser messageTime:(CGFloat)messageTime actionId:(long)actionId {
    
    NSError* error = nil;
    
    for (int i = 0; i < payload.length; i++) {
        // not sure why the resulting dictionary here is wrapped in an array but let's roll with it for now at least
        NSArray* payloadArray = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil && payloadArray.count > 1) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }
        
        NSLog(@"Received Compose message with payload: %@", payloadArray);
        
        NSString* invalidType;
        for (NSDictionary* contentDict in payloadArray) {
            if (!([contentDict[@"element"] isEqualToString:kUIComposeMessageElementSelect] || [contentDict[@"element"] isEqualToString:kUIComposeMessageElementButton])) {
                invalidType = contentDict[@"element"];
            }
        }
        
        if (invalidType == nil) {
            NINUIComposeMessage* msg = [NINUIComposeMessage messageWithID:messageID sender:messageUser timestamp:[NSDate dateWithTimeIntervalSince1970:messageTime] mine:[messageUser.userID isEqualToString:self.myUserID] payload:payloadArray];
            [self addNewChatMessage:msg];
        } else {
            NSLog(@"Found ui/compose object with unhandled element=%@, discarding message.", invalidType);
        }
    }
}

-(void) handleInboundMessage:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload actionId:(long)actionId {
    NSError* error = nil;

    NSString* messageID = [params getString:@"message_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* messageType = [params getString:@"message_type" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* messageUserID = [params getString:@"message_user_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    double messageTime;
    [params getFloat:@"message_time" val:&messageTime error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NINChannelUser* messageUser = _channelUsers[messageUserID];
    if (messageUser == nil) {
        NSLog(@"Message from unknown user: %@", messageUserID);
        //TODO how big a problem is this?
    }

    if ([messageType isEqualToString:kNINMessageTypeWebRTCIceCandidate] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCAnswer] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCOffer] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCCall] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCHangup] ||
        [messageType isEqualToString:kNINMessageTypeWebRTCPickup]) {

//        [self.ninchatSession sdklog:@"Got RTC signaling message from Ninchat API: %@", messageType];

        if (actionId != 0) {
            // This message originates from me; we can ignore it.
            return;
        }

        for (int i = 0; i < payload.length; i++) {
            // Handle a WebRTC signaling message
            NSDictionary* payloadDict = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
            if (error != nil) {
                NSLog(@"Failed to deserialize message JSON: %@", error);
                return;
            }

            postNotification(kNINWebRTCSignalNotification, @{@"messageType": messageType, @"payload": payloadDict, @"messageUser": messageUser});
        }
        return;
    }

    if ([messageType isEqualToString:@"ninchat.com/text"] || [messageType isEqualToString:@"ninchat.com/file"]) {
        [self handleInboundChatMessageWithPayload:payload messageID:messageID messageUser:messageUser messageTime:messageTime actionId:actionId];
        return;
    } else if ([messageType isEqualToString:@"ninchat.com/ui/compose"]) {
        [self handleInboundComposeMessageWithPayload:payload messageID:messageID messageUser:messageUser messageTime:messageTime actionId:actionId];
        return;
    } else if ([messageType isEqualToString:@"ninchat.com/info/channel"]) {
        [self handleChannelMessageWithPayload:payload messageID:messageID messageUser:messageUser messageTime:messageTime actionId:actionId];
        return;
    }

    // ignore messages other than the types we're explicitly handling
    NSLog(@"Ignoring unsupported message type: '%@'", messageType);
}

-(void) handlePartMessage:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload {
    for (int i = 0; i < payload.length; i++) {
        NSError* error = nil;
        NSArray* payloadArray = [NSJSONSerialization JSONObjectWithData:[payload get:i] options:0 error:&error];
        if (error != nil && payloadArray.count > 1) {
            NSLog(@"Failed to deserialize message JSON: %@", error);
            return;
        }
        
        NSLog(@"Received a Part message with payload: %@", payloadArray);
    }
}

-(void) messageReceived:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload {
    NSError* error = nil;
    
    NSString* messageType = [params getString:@"message_type" error:nil];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSLog(@"Received message of type '%@'", messageType);
    
    // handle transfers
    if ([messageType isEqualToString:@"ninchat.com/info/part"]) {
        [self handlePartMessage:params payload:payload];
        return;
    }
    
    NSCAssert(self.currentChannelID != nil || self.backgroundChannelID != nil, @"No active channel");

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");
    
    [self handleInboundMessage:params payload:payload actionId:actionId];

    if (actionId != 0) {
        postNotification(kActionNotification, @{@"action_id": @(actionId)});
    }
}

-(void) channelMemberUpdated:(NINLowLevelClientProps*)params {
    NSError* error = nil;

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NSString* channelID = [params getString:@"channel_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    if (![channelID isEqualToString:self.currentChannelID]
        && ![channelID isEqualToString:self.backgroundChannelID]) {
        [self.ninchatSession sdklog:@"Error: Got event for wrong channel: %@", channelID];
        return;
    }

    NSString* userID = [params getString:@"user_id" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    NINChannelUser* messageUser = _channelUsers[userID];
    if (messageUser == nil) {
        [self.ninchatSession sdklog:@"Update from unknown user: %@", userID];
        return;
    }

    if (![userID isEqualToString:self.myUserID]) {
        NINLowLevelClientProps* memberAttrs = [params getObject:@"member_attrs" error:&error];
        NSCAssert(error == nil, @"Failed to get attribute");

        BOOL writing = NO;
        [memberAttrs getBool:@"writing" val:&writing error:&error];
        NSCAssert(error == nil, @"Failed to get attribute");

        // Check if that user already has a 'writing' message
        NSInteger messageIndex = -1;

        for (NSInteger i = 0; i < _chatMessages.count; i++) {
            NINUserTypingMessage* msg = (NINUserTypingMessage*)_chatMessages[i];
            if ([msg isKindOfClass:NINUserTypingMessage.class] && [msg.user.userID isEqualToString:userID]) {
                messageIndex = i;
                break;
            }
        }

        if (writing) {
            if (messageIndex < 0) {
                // There's no 'typing' message for this user yet, lets create one
                [self addNewChatMessage:[NINUserTypingMessage messageWithUser:messageUser timestamp:NSDate.date]];
            }
        } else {
            if (messageIndex >= 0) {
                // There's a 'typing' message for this user - lets remove that.
                [self removeChatMessageAtIndex:messageIndex];
            }
        }
    }

    postNotification(kActionNotification, @{@"action_id": @(actionId)});
}

/*
 Event: map[event_id:2 action_id:1 channel_id:5npnrkp1009n error_type:channel_not_found event:error]
 */
-(void) handleError:(NINLowLevelClientProps*)params {
    NSError* error = nil;
    NSString* errorType = [params getString:@"error_type" error:&error];
    if (error != nil) {
        NSLog(@"Failed to read error type: %@", error);
        return;
    }

    long actionId;
    [params getInt:@"action_id" val:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Failed to get action_id: %@", error);
        return;
    }

    postNotification(kActionNotification, @{@"action_id": @(actionId), @"error": newError(errorType)});
}

#pragma mark - Public methods

-(BOOL) connected {
    return self.session != nil;
}

-(void) listQueuesWithIds:(NSArray<NSString*>*)queueIds completion:(callbackWithErrorBlock)completion {
    NSCAssert(self.session != nil, @"No chat session");

    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"describe_realm_queues"];
    [params setString:@"realm_id" val:self.realmId];
    if (queueIds != nil) {
        NINLowLevelClientStrings* strings = [NINLowLevelClientStrings new];
        for (NSString* string in queueIds) {
            [strings append:string];
        }
        [params setStringArray:@"queue_ids" ref:strings];
    }

    NSError* error = nil;
    int64_t actionId;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error describing queues: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

-(void) joinQueueWithId:(NSString*)joinQueueID progress:(queueProgressCallback _Nonnull)progress channelJoined:(emptyBlock _Nonnull)channelJoined {

    NSCAssert(self.session != nil, @"No chat session");
    NSCAssert(self.queueProgressObserver == nil, @"Cannot have observer set already");

    // when transferred we're kind of just dropped into the new queue, but we'll still need to set up observers again
    BOOL alreadyInQueue = (self.currentQueueID != nil);

    __weak typeof(self) weakSelf = self;

    // This block does the actual operation
    void(^performJoin)(void) = ^() {
        [weakSelf.ninchatSession sdklog:@"Joining queue %@..", joinQueueID];

        weakSelf.channelJoinObserver = fetchNotification(kChannelJoinedNotification, ^BOOL(NSNotification* note) {
            [NSNotificationCenter.defaultCenter removeObserver:weakSelf.queueProgressObserver];
            weakSelf.queueProgressObserver = nil;

            channelJoined();
            return YES;
        });

        if (!alreadyInQueue) {
            NINLowLevelClientProps* params = [NINLowLevelClientProps new];
            [params setString:@"action" val:@"request_audience"];
            [params setString:@"queue_id" val:joinQueueID];
            if (weakSelf.audienceMetadata != nil) {
                [params setObject:@"audience_metadata" ref:weakSelf.audienceMetadata];
            }

            int64_t actionId;
            NSError* error = nil;
            [weakSelf.session send:params payload:nil actionId:&actionId error:&error];
            if (error != nil) {
                NSLog(@"Error joining queue: %@", error);
                progress(error, -1);
            }
        }

        // Keep listening to progress events for queue position updates
        weakSelf.queueProgressObserver = fetchNotification(kActionNotification, ^(NSNotification* note) {
            NSString* eventType = note.userInfo[@"event"];
            NSString* queueID = note.userInfo[@"queue_id"];

            if ([eventType isEqualToString:@"queue_updated"] && [weakSelf.currentQueueID isEqualToString:queueID]) {
                NSError* error = note.userInfo[@"error"];
                NSInteger queuePosition = [note.userInfo[@"queue_position"] intValue];
                progress(error, queuePosition);
            }

            return NO;
        });
    };

    if (self.currentChannelID != nil) {
        [self.ninchatSession sdklog:@"Parting current channel first"];

        [self partChannel:self.currentChannelID completion:^(NSError* error) {
            [weakSelf.ninchatSession sdklog:@"Channel parted; joining queue."];
            weakSelf.backgroundChannelID = weakSelf.currentChannelID;
            weakSelf.currentChannelID = nil;
            performJoin();
        }];
    } else {
        performJoin();
    }
}

// Leaves the current queue, if any
-(void) leaveCurrentQueueWithCompletionCallback:(callbackWithErrorBlock _Nonnull)completion {
    if (self.currentQueueID == nil) {
        [self.ninchatSession sdklog:@"Error: tried to leave current queue but not in queue currently!"];
        return;
    }

    [self.ninchatSession sdklog:@"Leaving current queue."];

    // Stop the queue observers
    [NSNotificationCenter.defaultCenter removeObserver:self.channelJoinObserver];
    self.channelJoinObserver = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self.queueProgressObserver];
    self.queueProgressObserver = nil;

    completion(nil);
}

// Retrieves the WebRTC ICE STUN/TURN server details
-(void) beginICEWithCompletionCallback:(beginICECallbackBlock _Nonnull)completion {
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"begin_ice"];

    int64_t actionId;
    NSError* error = nil;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error calling begin_ice: %@", error);
        completion(error, nil, nil);
    }

    // When this action completes, trigger the completion block callback
    fetchNotification(kActionNotification, ^(NSNotification* note) {
        NSNumber* eventActionId = note.userInfo[@"action_id"];

        if (eventActionId.longValue == actionId) {
            NSError* error = note.userInfo[@"error"];
            NSArray* stunServers = note.userInfo[@"stunServers"];
            NSArray* turnServers = note.userInfo[@"turnServers"];

            completion(error, stunServers, turnServers);
            return YES;
        }

        return NO;
    });
}

// Sends a message to the activa channel. Active channel must exist.
-(int64_t) sendMessageWithMessageType:(NSString*)messageType payloadDict:(NSDictionary*)payloadDict completion:(callbackWithErrorBlock _Nonnull)completion {

    NSCAssert(self.session != nil, @"No chat session");

    if (self.currentChannelID == nil) {
        completion(newError(@"No active channel"));
        return -1;
    }

    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"send_message"];
    [params setString:@"message_type" val:messageType];
    [params setString:@"channel_id" val:self.currentChannelID];

    if ([messageType isEqualToString:@"ninchat.com/metadata"] && payloadDict[@"data"][@"rating"] != nil) {
        [params setStringArray:@"message_recipient_ids" ref:[NINLowLevelClientStrings new]];
        [params setBool:@"message_fold" val:YES];
    }

    if ([messageType hasPrefix:@"ninchat.com/rtc/"]) {
        // Add message_ttl to all rtc signaling messages
        [params setInt:@"message_ttl" val:10];
    }

    NSError* error;
    NSData* payloadContentJsonData = [NSJSONSerialization dataWithJSONObject:payloadDict options:0 error:&error];
    if (error != nil) {
        NSLog(@"Failed to serialize message JSON: %@", error);
        completion(error);
        return -1;
    }

    NINLowLevelClientPayload* payload = [NINLowLevelClientPayload new];
    [payload append:payloadContentJsonData];

    int64_t actionId = -1;
    [self.session send:params payload:payload actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error sending message: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);

    return actionId;
}

// Sends a text message to the current channel
-(void) sendTextMessage:(NSString*)message completion:(callbackWithErrorBlock _Nonnull)completion {
    NSCAssert(self.session != nil, @"No chat session");

    NSDictionary* payloadDict = @{@"text": message};
    [self sendMessageWithMessageType:@"ninchat.com/text" payloadDict:payloadDict completion:completion];
}

// Sends a ui/action response to the current channel
-(void) sendUIActionMessage:(NSDictionary*)composeMessageDict completion:(callbackWithErrorBlock _Nonnull)completion {
    NSCAssert(self.session != nil, @"No chat session");
    
    NSDictionary* payloadDict = @{@"action": @"click",
                                  @"target": composeMessageDict};
    [self sendMessageWithMessageType:@"ninchat.com/ui/action" payloadDict:payloadDict completion:completion];
}

-(void) sendFileWithFilename:(NSString*)fileName withData:(NSData*)data completion:(callbackWithErrorBlock _Nonnull)completion {
    NSCAssert(self.session != nil, @"No chat session");

    if (self.currentChannelID == nil) {
        completion(newError(@"No active channel"));
        return;
    }

    NINLowLevelClientProps* fileAttributes = [NINLowLevelClientProps new];
    [fileAttributes setString:@"name" val:fileName];

    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"send_file"];
    [params setObject:@"file_attrs" ref:fileAttributes];
    [params setString:@"channel_id" val:self.currentChannelID];

    NINLowLevelClientPayload* payload = [NINLowLevelClientPayload new];
    [payload append:data];

    [self.ninchatSession sdklog:@"Sending file: %@, length: %ld", params.string, data.length];

    NSError* error = nil;
    int64_t actionId = -1;
    [self.session send:params payload:payload actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error sending file: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

-(void) partChannel:(NSString*)channelID completion:(callbackWithErrorBlock _Nonnull)completion {
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"part_channel"];
    [params setString:@"channel_id" val:channelID];

    NSError* error = nil;
    int64_t actionId = -1;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error parting channel: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

-(void) setIsWriting:(BOOL)isWriting completion:(callbackWithErrorBlock _Nonnull)completion {
    NSCAssert(self.currentChannelID != nil, @"Must have current channel");

    NINLowLevelClientProps* memberAttrs = [NINLowLevelClientProps new];
    [memberAttrs setBool:@"writing" val:isWriting];

    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"update_member"];
    [params setString:@"channel_id" val:self.currentChannelID];
    [params setString:@"user_id" val:self.myUserID];
    [params setObject:@"member_attrs" ref:memberAttrs];

    NSError* error = nil;
    int64_t actionId = -1;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error sending update_member message for writing: setting: %@", error);
        completion(error);
    }

    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

-(void) loadHistoryWithCompletion:(callbackWithErrorBlock _Nonnull)completion {
    NSCAssert(self.currentChannelID != nil, @"Must have current channel");
    
    NINLowLevelClientProps* params = [NINLowLevelClientProps new];
    [params setString:@"action" val:@"load_history"];
    [params setString:@"channel_id" val:self.currentChannelID];
    
    NSError* error = nil;
    int64_t actionId = -1;
    [self.session send:params payload:nil actionId:&actionId error:&error];
    if (error != nil) {
        NSLog(@"Error loading channel history: %@", error);
        completion(error);
    }
    
    // When this action completes, trigger the completion block callback
    connectCallbackToActionCompletion(actionId, completion);
}

-(void) disconnect {
    [self.ninchatSession sdklog:@"disconnect: Closing Ninchat session."];

    [_messageThrottler stop];
    _messageThrottler = nil;
    
    self.currentChannelID = nil;
    self.backgroundChannelID = nil;
    self.currentQueueID = nil;

    [self.session close];
    self.session = nil;
    self.sessionCallbackHandler = nil;
}

// Low-level shutdown of the chatsession; invalidates session resource.
-(void) closeChat {
    [self.ninchatSession sdklog:@"Shutting down chat Session.."];

    // Delete our guest user.
    __weak typeof(self) weakSelf = self;
    [self deleteCurrentUserWithCompletion:^(NSError* error) {
        [weakSelf disconnect];

        // Signal the delegate that our session has ended
        [weakSelf.ninchatSession.delegate ninchatDidEndSession:weakSelf.ninchatSession];
    }];
}

// High-level chat ending; sends channel metadata and then closes session.
-(void) finishChat:(NSNumber* _Nullable)rating {
    NSCAssert(self.session != nil, @"No chat session");

    if (rating != nil) {
        NSDictionary* payloadDict = @{@"data": @{@"rating": rating}};

        __weak typeof(self) weakSelf = self;
        [self sendMessageWithMessageType:@"ninchat.com/metadata" payloadDict:payloadDict completion:^(NSError* error) {
            [weakSelf closeChat];
        }];
    } else {
        [self closeChat];
    }
}

-(NSError*) openSession:(startCallbackBlock _Nonnull)callbackBlock {
    NSCAssert(self.session == nil, @"Existing chat session found");
    NSCAssert(self.serverAddress != nil, @"Must have server address");

    [self.ninchatSession sdklog:@"Opening new chat session using server address %@", self.serverAddress];

    // Create message throttler to manage inbound message order
    __weak NINSessionManager* weakSelf = self;
    _messageThrottler = [NINMessageThrottler throttlerWithCallback:^(NINInboundMessage * _Nonnull message) {
        [weakSelf messageReceived:message.params payload:message.payload];
    }];
    
    // Make sure our site configuration contains a realm_id
    NSString* realmId = [self.siteConfiguration valueForKey:@"audienceRealmId"];
    if ((realmId == nil) || (![realmId isKindOfClass:[NSString class]])) {
        return newError(@"Could not find valid realm id in the site configuration");
    }

    self.realmId = realmId;

    NINLowLevelClientStrings* messageTypes = [NINLowLevelClientStrings new];
    [messageTypes append:@"ninchat.com/*"];

    NINLowLevelClientProps* sessionParams = [NINLowLevelClientProps new];
    if (self.siteSecret != nil) {
        [sessionParams setString:@"site_secret" val:self.siteSecret];
    }

    // Get the username from the site config
    NSString* userName = [self.siteConfiguration valueForKey:@"userName"];
    if (userName != nil) {
        NINLowLevelClientProps* attrs = [NINLowLevelClientProps new];
        [attrs setString:@"name" val:userName];
        [sessionParams setObject:@"user_attrs" ref:attrs];
    }

    [sessionParams setStringArray:@"message_types" ref:messageTypes];

    // Wait for the session creation event
    fetchNotification(kActionNotification, ^BOOL(NSNotification* _Nonnull note) {
        NSString* eventType = note.userInfo[@"event_type"];
        if ([eventType isEqualToString:@"session_created"]) {
            callbackBlock(note.userInfo[@"error"]);
            return YES;
        }

        return NO;
    });

    self.sessionCallbackHandler = [SessionCallbackHandler handlerWithSessionManager:self];
    self.session = [NINLowLevelClientSession new];
    [self.session setAddress:self.serverAddress];
    [self.session setOnClose:self.sessionCallbackHandler];
    [self.session setOnConnState:self.sessionCallbackHandler];
    [self.session setOnLog:self.sessionCallbackHandler];
    [self.session setOnSessionEvent:self.sessionCallbackHandler];
    [self.session setOnEvent:self.sessionCallbackHandler];

    NSError* error = nil;
    [self.session setParams:sessionParams error:&error];
    if (error != nil) {
        NSLog(@"Error setting session params: %@", error);
        return error;
    }
    [self.session open:&error];
    if (error != nil) {
        NSLog(@"Error opening session: %@", error);
        return error;
    }

    return nil;
}

-(NSString*) translation:(NSString*)keyName formatParams:(NSDictionary<NSString*,NSString*>*)formatParams {
    // Look for a translation. If one is not available for this key, use the key itself.
    NSString* translation = [self.siteConfiguration valueForKey:@"translations"][keyName];
    if (translation == nil) {
        translation = keyName;
    }

    for (NSString* formatKey in formatParams.allKeys) {
        NSString* formatValue = formatParams[formatKey];
        translation = [translation stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{{%@}}", formatKey] withString:formatValue];
    }

    return translation;
}

#pragma mark - 

-(void) onEvent:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload lastReply:(BOOL)lastReply {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

    NSError* error = nil;
    NSString* event = [params getString:@"event" error:&error];
    if (error != nil) {
        NSLog(@"Got error getting event data: %@", error);
        return;
    }

    if ([event isEqualToString:@"error"]) {
        [self handleError:params];
    } else if ([event isEqualToString:@"channel_joined"]) {
        [self channelJoined:params];
    } else if ([event isEqualToString:@"message_received"]) {
        // Throttle the message; it will be cached for a short while to ensure inbound message order.
        [_messageThrottler addMessage:[NINInboundMessage messageWithParams:params andPayload:payload]];
    } else if ([event isEqualToString:@"realm_queues_found"]) {
        [self realmQueuesFound:params];
    } else if ([event isEqualToString:@"audience_enqueued"] || [event isEqualToString:@"queue_updated"]) {
        [self queueUpdated:event params:params];
    } else if ([event isEqualToString:@"channel_updated"]) {
        [self channelUpdated:params];
    } else if ([event isEqualToString:@"ice_begun"]) {
        [self iceBegun:params];
    } else if ([event isEqualToString:@"user_updated"]) {
        [self userUpdated:params];
    } else if ([event isEqualToString:@"file_found"]) {
        [self fileFound:params];
    } else if ([event isEqualToString:@"channel_parted"]) {
        [self channelParted:params];
    } else if ([event isEqualToString:@"channel_member_updated"]) {
        [self channelMemberUpdated:params];
    }

    // Forward the event to the SDK delegate
    if ([self.ninchatSession.delegate respondsToSelector:@selector(ninchat:onLowLevelEvent:payload:lastReply:)]) {
        [self.ninchatSession.delegate ninchat:self.ninchatSession onLowLevelEvent:params payload:payload lastReply:lastReply];
    }
}

-(void) onLog:(NSString*)msg {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

}

-(void) onConnState:(NSString*)state {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

}

-(void) onClose {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

}

-(void) onSessionEvent:(NINLowLevelClientProps*)params {
    NSCAssert([NSThread isMainThread], @"Must be called on main thread");

    NSError* error = nil;
    NSString* event = [params getString:@"event" error:&error];
    NSCAssert(error == nil, @"Failed to get attribute");

    if ([event isEqualToString:@"session_created"]) {
        self.myUserID = [params getString:@"user_id" error:&error];
        NSCAssert(error == nil, @"Failed to get attribute");

        [self.ninchatSession sdklog:@"Session created - my user ID is: %@", self.myUserID];

        postNotification(kActionNotification, @{@"event_type": event});
    } else if ([event isEqualToString:@"user_deleted"]) {
        [self userDeleted:params];
    }
}

#pragma mark - Lifecycle etc.

-(void) dealloc {
    [self disconnect];

    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

-(id) init {
    self = [super init];

    if (self != nil) {
        _queues = [NSMutableArray array];
        _chatMessages = [NSMutableArray array];
        _channelUsers = [NSMutableDictionary dictionary];
    }

    return self;
}

@end

#pragma mark - SessionCallbackHandler

@implementation SessionCallbackHandler

+(instancetype) handlerWithSessionManager:(NINSessionManager*)sessionManager {
    SessionCallbackHandler* handler = [SessionCallbackHandler new];
    handler.sessionManager = sessionManager;
    return handler;
}

-(void) onEvent:(NINLowLevelClientProps*)params payload:(NINLowLevelClientPayload*)payload lastReply:(BOOL)lastReply {
    runOnMainThread(^{
        [self.sessionManager onEvent:params payload:payload lastReply:lastReply];
    });
}

-(void) onClose {
    runOnMainThread(^{
        [self.sessionManager onClose];
    });
}

-(void) onSessionEvent:(NINLowLevelClientProps*)params {
    runOnMainThread(^{
        [self.sessionManager onSessionEvent:params];
    });
}

-(void) onLog:(NSString*)msg {
    runOnMainThread(^{
        [self.sessionManager onLog:msg];
    });
}

-(void) onConnState:(NSString*)state {
    runOnMainThread(^{
        [self.sessionManager onConnState:state];
    });
}

//-(void) dealloc {
//    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
//}

@end


