//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatLowLevelClient

typealias CompletionWithError = ((Error?) -> Void)
typealias Completion = (() -> Void)

/* Available ratings and assigned status codes for finishing the chat from our end */
enum ChatStatus: Int {
    case happy = 1
    case neutral = 0
    case sad = -1
}

protocol NINChatSessionConnectionManager {
    /** Low-level chat session reference. */
    var session: NINLowLevelClientSession? { get }
    
    /** Whether or not this session is connected. */
    var connected: Bool! { get }
    
    /** Fetch site's configuration using given `server address` in the initialization */
    func fetchSiteConfiguration(config key: String, environments: [String]?, completion: @escaping CompletionWithError)
    
    /** Opens the session with an asynchronous completion callback. */
    func openSession(completion: @escaping CompletionWithError) throws
    
    /** List queues with specified ids for this realm, all available ones if queueIds is nil. */
    func list(queues ID: [String]?, completion: @escaping CompletionWithError) throws
    
    /** Joins a chat queue. */
    func join(queue ID: String, progress: @escaping ((Queue?, Error?, Int) -> Void), completion: @escaping Completion) throws
    
    /** Leaves the current queue. */
    func leave(completion: @escaping CompletionWithError)
    
    /** Runs ICE (Interactive Connectivity Establishment) for WebRTC connection negotiations. */
    func beginICE(completion: @escaping ((Error?, [WebRTCServerInfo]?, [WebRTCServerInfo]?) -> Void)) throws
    
    /** Closes the chat by shutting down the session. Triggers the API delegate method -ninchatDidEndChatSession:. */
    func closeChat() throws
    
    /** (Optionally) sends ratings and finishes the current chat from our end. */
    func finishChat(rating status: ChatStatus?) throws
}

protocol NANChatSessionMessenger {
    /**
    * Chronological list of messages on the current channel. The list is ordered by the message
    * timestamp in descending order (most recent first).
    */
    var chatMessages: [ChatMessage]! { get }
    
    /** Indicate whether or not the user is currently typing into the chat. */
    func update(isWriting: Bool, completion: @escaping CompletionWithError) throws
    
    /** Sends chat message to the active chat channel. */
    func send(message: String, completion: @escaping CompletionWithError) throws
    
    /** Sends a ui/action response to the current channel. */
    func send(action: ComposeContentViewProtocol, completion: @escaping CompletionWithError) throws
    
    /** Sends a file to the chat. */
    func send(attachment: String, data: Data, completion: @escaping CompletionWithError) throws
    
    /** Sends a message to the active channel. Active channel must exist. */
    @discardableResult
    func send(type: MessageType, payload: [String:Any], completion: @escaping CompletionWithError) throws -> Int?
    
    /** Load channel history. */
    func loadHistory(completion: @escaping CompletionWithError) throws
}

protocol NINChatSessionAttachment {
    /** Describe a file by its ID. */
    func describe(file id: String, completion: @escaping ((Error?, [String:Any]?) -> Void)) throws
}

protocol NINChatSessionTranslation {
    /**
    * Get a formatted translation from the site configuration.
    * @param formatParams contains format param mappings key -> value
    */
    func translate(key: String, formatParams: [String:String]) -> String?
}

protocol QueueUpdateCapture {
    var desc: String { get }
}

protocol NINChatSessionManagerDelegate {
    var onMessageAdded: ((_ index: Int) -> Void)? { get set }
    var onMessageRemoved: ((_ index: Int) -> Void)? { get set }
    var onChannelClosed: (() -> Void)? { get set }
    var onRTCSignal: ((MessageType, ChannelUser?, _ signal: RTCSignal?) -> Void)? { get set }
    var onRTCClientSignal: ((MessageType, ChannelUser?, _ signal: RTCSignal?) -> Void)? { get set }

    func bindQueueUpdate<T: QueueUpdateCapture>(closure: @escaping ((Events, Queue, Error?) -> Void), to receiver: T)
    func unbindQueueUpdateClosure<T: QueueUpdateCapture>(from receiver: T)
}

protocol NINChatSessionManager: class, NINChatSessionConnectionManager, NANChatSessionMessenger, NINChatDevHelper, NINChatSessionAttachment, NINChatSessionTranslation, NINChatSessionManagerDelegate {
    /** List of available queues for the realm_id. */
    var queues: [Queue]! { get set }
    
    /** List of Audience queues. These are the queues the user gets to pick from in the UI. */
    var audienceQueues: [Queue]! { get set }
    
    /** Site configuration. */
    var siteConfiguration: SiteConfiguration! { get }
    
    /** A weak reference to internal functions declared in `NINChatSessionSwift` */
    var delegate: NINChatSessionInternalDelegate? { get }
    
    /** Host application details including name, version, and some more details.
    *   will be appended to some predefined values such as SDK version, device OS, and device model.
    */
    var appDetails: String? { get set }
    
    /** Default initializer for NinchatSessionManager. */
    init(session: NINChatSessionInternalDelegate?, serverAddress: String, audienceMetadata: NINLowLevelClientProps?)
}
