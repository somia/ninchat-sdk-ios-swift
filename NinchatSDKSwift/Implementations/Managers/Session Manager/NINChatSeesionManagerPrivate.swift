//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import NinchatSDK

// MARK: - Private helper functions - delegates

extension NINChatSessionManagerImpl {
    internal func didRealmQueuesFind(param: NINLowLevelClientProps) throws {
        /// Clear existing queue list
        sessionSwift.ninchat(sessionSwift, didOutputSDKLog: "Realm queues found - flushing list of previously available queues.")
        queues.removeAll()
        
        let queuesParser = NINClientPropsParser()
        let actionID = try param.actionID()
        
        do {
            let realmQueues = try param.realmQueue()
            try realmQueues.accept(queuesParser)
            
            self.queues = queuesParser.properties.keys.compactMap({ key in
                NINQueue(id: key, andName: try? realmQueues.getObject(key).queueAttributes_Name())
            })
            
            /// Form the list of audience queues; if audienceQueues is specified in siteConfig, we use those;
            /// if not, we use the complete list of queues.
            if let audienceQueueIDs = self.configuration.audienceQueues {
                self.audienceQueues = audienceQueueIDs.compactMap { [weak self] id in
                    /// Returns the queue with given id
                    self?.queues.filter({ $0.queueID == id }).compactMap({ $0 }).first
                }
            }
            self.onActionID?(actionID, nil)
        } catch {
            self.onActionID?(actionID, error)
        }
    }
    
    /// https://github.com/ninchat/ninchat-api/blob/v2/api.md#audience_enqueued
    /// https://github.com/ninchat/ninchat-api/blob/v2/api.md#queue_updated
    internal func didUpdateQueue(type: Events, param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        do {
            let queueID = try param.queueID()
            do {
                let position = try param.queuePosition()
                if actionID != 0 || type == .queueUpdated {
                    self.onQueueUpdated?(type, queueID, position, nil)
                } else if type == .audienceEnqueued {
                    guard self.currentQueueID == nil else { throw NINSessionExceptions.hasActiveChannel }
                    self.currentQueueID = queueID
                    self.onQueueUpdated?(type, queueID, position, nil)
                }
            } catch {
                self.onQueueUpdated?(type, queueID, nil, error)
            }
        } catch {
           self.onActionID?(actionID, error)
       }
    }
    
    internal func didUpdateUser(param: NINLowLevelClientProps) throws {
        guard self.currentChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        
        let userID = try param.userID()
        self.channelUsers[userID] = parse(userAttr: try param.userAttributes(), userID: userID)
    }
    
    internal func didFindFile(param: NINLowLevelClientProps) throws {
        let thumbnail = try? param.fileAttributes_ThumbnailSize()
        let aspectRatio: Double = (thumbnail != nil) ? Double(thumbnail!.width/thumbnail!.height) : 1.0
            
        let actionID = try param.actionID()
        do {
            let fileURL = try param.fileURL()
            let urlExpiry = try param.urlExpiry()
            
            self.onActionFileInfo?(actionID, ["aspectRatio": aspectRatio, "url": fileURL, "urlExpiry": urlExpiry], nil)
        } catch {
            self.onActionFileInfo?(actionID, nil, error)
        }
    }
    
    internal func didDeleteUser(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        do {
            let userID = try param.userID()
            if userID == myUserID {
                sessionSwift.ninchat(sessionSwift, didOutputSDKLog: "Current user deleted.")
            }
            self.onActionID?(actionID, nil)
        } catch {
            self.onActionID?(actionID, error)
        }
    }
    
    internal func didJoinChannel(param: NINLowLevelClientProps) throws {
        guard currentQueueID != nil else { throw NINSessionExceptions.noActiveQueue }
        guard currentChannelID == nil else { throw NINSessionExceptions.noActiveChannel }
        
        do {
            let channelID = try param.channelID()
            
            sessionSwift.ninchat(sessionSwift, didOutputSDKLog: "Joined channel ID: \(channelID)")

            /// Set the currently active channel
            self.currentChannelID = channelID
            self.backgroundChannelID = nil

            /// Get the queue we are joining
            let queueName = self.queues.compactMap({ $0 }).filter({ [weak self] queue in
                queue.queueID == self?.currentChannelID }).first?.name ?? ""
            
            /// We are no longer in the queue; clear the queue reference
            self.currentQueueID = nil;

            /// Clear current list of messages and users
            chatMessages.removeAll()
            channelUsers.removeAll()
            
            /// Insert a meta message about the conversation start
            self.add(message: NINChatMetaMessage(text: self.translate(key: "Audience in queue {{queue}} accepted.", formatParams: ["queue": queueName]), timestamp: Date(), closeChatButtonTitle: nil))

            /// Extract the channel members' data
            do {
                let parser = NINClientPropsParser()
                let members = try param.channelMembers()
                try members.accept(parser)
                
                try parser.properties.compactMap({ dict in
                    (dict.key, dict.value) as? (String,NINLowLevelClientProps)
                }).map({ key, value in
                    try (key, value.userAttributes())
                }).forEach({ [weak self] userID, attributes in
                    self?.channelUsers[userID] = self?.parse(userAttr: attributes, userID: userID)
                })
            } catch {
                debugger(error.localizedDescription)
            }
            
            /// Signal channel join event to the asynchronous listener
            self.onChannelJoined?()
        } catch {
            throw NINSessionExceptions.noParamChannel
        }
    }
    
    internal func didPartChannel(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        do {
            let channelID = try param.channelID()
            
            /// No body is listening to this closure, so, what? :D
            self.onActionChannel?(actionID, channelID)
        } catch {
            self.onActionID?(actionID, error)
        }
    }
    
    internal func didUpdateChannel(param: NINLowLevelClientProps) throws {
        guard currentChannelID != nil || backgroundChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        
        let channelID = try param.channelID()
        guard channelID == currentChannelID || channelID == backgroundChannelID else {
            debugger("Got channel_updated for wrong channel: \(channelID)")
            return
        }
        
        let channelClosed = try param.channelClosed()
        let channelSuspended = try param.channelSuspended()
        if channelClosed || channelSuspended {
            let text = self.translate(key: "Conversation ended", formatParams: nil)
            let closeTitle = self.translate(key: "Close chat", formatParams: nil)
            self.add(message: NINChatMetaMessage(text: text, timestamp: Date(), closeChatButtonTitle: closeTitle))
            self.onChannelClosed?()
        }
    }
    
    /// Processes the response to the WebRTC connectivity ICE query
   internal func didBeginICE(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        
        do {
            let stunServersParam = try param.stunServers()
            let turnServersParam = try param.turnServers()
            
            /// Parse the STUN server list
            let stunServers = try [Int](0..<stunServersParam.length()).map({ index -> NINLowLevelClientProps in
                stunServersParam.get(index)
            }).compactMap({ prop -> NINLowLevelClientStrings in
                try prop.srversURLs()
            }).compactMap({ servers -> ([Int], NINLowLevelClientStrings) in
                ([Int](0..<servers.length()), servers)
            }).map({ (indexArray, serversArray) -> [NINWebRTCServerInfo] in
                return indexArray.map { NINWebRTCServerInfo.server(withURL: serversArray.get($0), username: "", credential: "") }
            }).reduce([], +)
            
            /// Parse the TURN server list
            let turnServers = try [Int](0..<turnServersParam.length()).map({ index -> NINLowLevelClientProps in
                turnServersParam.get(index)
            }).compactMap({ prop -> (NINLowLevelClientStrings, String, String) in
                (try prop.srversURLs(), try prop.turnServers_UserName(), try prop.turnServers_Credential())
            }).compactMap({ (servers, userName, credential) -> ([Int], NINLowLevelClientStrings, String, String) in
                ([Int](0..<servers.length()), servers, userName, credential)
            }).map({ (indexArray, serversArray, userName, credential) -> [NINWebRTCServerInfo] in
                return indexArray.map { NINWebRTCServerInfo.server(withURL: serversArray.get($0), username: userName, credential: credential) }
            }).reduce([], +)
            
            self.onActionSevers?(actionID, stunServers, turnServers)
        } catch {
            self.onActionID?(actionID, error)
        }
    }
   
   internal func parse(userAttr: NINLowLevelClientProps, userID: String) -> NINChannelUser? {
        do {
            return NINChannelUser(id: userID, realName: try userAttr.userAttributes_RealName(), displayName: try userAttr.userAttributes_DisplayName(), iconURL: try userAttr.userAttributes_IconURL(), guest: try userAttr.userAttributes_IsGuest())
        } catch {
            return nil
        }
    }
    
    internal func didReceiveMessage(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload) throws {
        let messageType = try param.messageType()
        debugger("Received message of type \(String(describing: messageType))")
        
        /// handle transfers
        if messageType == .part {
            try self.handlePart(param: param, payload: payload); return
        }
        
        guard currentChannelID != nil || backgroundChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        let actionID = try param.actionID()

        do {
            try self.handleInbound(param: param, actionID: actionID, payload: payload)
            if actionID != 0 { self.onActionID?(actionID, nil) }
        } catch {
            if actionID != 0 { self.onActionID?(actionID, error) }
        }
    }
    
    internal func didUpdateMember(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        
        do {
            let channelID = try param.channelID()
            guard channelID != currentChannelID, channelID != backgroundChannelID else {
                self.sessionSwift.ninchat(sessionSwift, didOutputSDKLog: "Error: Got event for wrong channel: \(channelID)")
                return
            }
            
            let userID = try param.userID()
            guard let messageUser = channelUsers[userID] else {
                self.sessionSwift.ninchat(sessionSwift, didOutputSDKLog: "Update from unknown user: \(userID)")
                return
            }
            
            if userID != myUserID {
                let isWriting = try param.memberAttributes().writing()
                
                /// Check if that user already has a 'writing' message
                let writingMessage = chatMessages.filter({ ($0 as? NINUserTypingMessage)?.user.userID == userID }).first as? NINUserTypingMessage
                if isWriting, writingMessage == nil {
                    /// There's no 'typing' message for this user yet, lets create one
                    self.add(message: NINUserTypingMessage(user: messageUser, timestamp: Date()))
                } else if let msg = writingMessage {
                    /// There's a 'typing' message for this user - lets remove that.
                    self.removeMessage(atIndex: (chatMessages as NSArray).index(of: msg))
                }
            }
            
            self.onActionID?(actionID, nil)
        } catch {
            self.onActionID?(actionID, error)
        }
    }
}

// MARK: - Private helper functions - actions

extension NINChatSessionManagerImpl {
    /// Deletes the current user.
    internal func deleteCurrentUser(completion: @escaping ((Error?) -> Void)) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        let param = NINLowLevelClientProps.initiate
        param.set_deleteUser()
        
        do {
            let actionID = try session.send(param)
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
    
    internal func add(message: NINChatMessage) {
        // Check if the previous (normal) message was sent by the same user, ie. is the
        // message part of a series
        if let channelMessage = message as? NINChannelMessage {
            // Guard against the same message getting added multiple times
            // should only happen if the client makes extraneous load_history calls elsewhere
            guard self.chatMessages.filter({
                ($0 as? NINChannelMessage)?.messageID == channelMessage.messageID
            }).count == 0 else { return }
            
            // Find the previous channel message
            if let prevMsg = chatMessages.compactMap({ $0 as? NINTextMessage }).last {
                channelMessage.series = prevMsg.sender.userID == channelMessage.sender.userID
            } else {
                channelMessage.series = false
            }
        }
        
        chatMessages.insert(message, at: 0)
        chatMessages.sort { $0.timestamp.compare($1.timestamp) == .orderedAscending }
        self.onMessageAdded?((chatMessages as NSArray).index(of: message))
    }
    
    internal func removeMessage(atIndex index: Int) {
        chatMessages.remove(at: index)
        self.onMessageRemoved?(index)
    }
    
    internal func part(channel ID: String, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        let param = NINLowLevelClientProps.initiate
        param.set_partChannel()
        param.set(channel: ID)
        
        do {
            let actionID = try session.send(param)
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
    
    internal func disconnect() {
        self.sessionSwift.ninchat(sessionSwift, didOutputSDKLog: "disconnect: Closing Ninchat session.")
        
        self.messageThrottler?.stop()
        self.messageThrottler = nil
        
        self.currentChannelID = nil
        self.backgroundChannelID = nil
        self.currentQueueID = nil
        
        self.session?.close()
        self.session = nil
    }
}

// MARK: - Private helper functions - handlers

extension NINChatSessionManagerImpl {
    internal func handleInbound(param: NINLowLevelClientProps, actionID: Int, payload: NINLowLevelClientPayload) throws {
        
        let messageID = try param.messageID()
        let messageUserID = try param.messageUserID()
        let messageTime = try param.messageTime()
        guard let messageUser = self.channelUsers[messageUserID] else {
            debugger("Message from unknown user: \(messageUserID)")
            return
        }
        
        if let messageType = try param.messageType() {
            switch messageType {
            case .candidate, .answer, .offer, .call, .pickup, .hangup:
                /// This message originates from me; we can ignore it.
                if actionID != 0 { return }
                
                try [Int](0..<payload.length()).forEach { [weak self] index in
                    /// Handle a WebRTC signaling message
                    let decode: Result<RTCSignal> = payload.get(index)!.decode()
                    switch decode {
                    case .success(let signal):
                        self?.onRTCSignal?(signal)
                    case .failure(let error):
                        throw error
                    }
                }
            case .text, .file:
                try self.handleInbound(message: messageID, user: messageUser, time: messageTime, actionID: actionID, payload: payload)
            case .compose:
                try self.handleCompose(message: messageID, user: messageUser, time: messageTime, actionID: actionID, payload: payload)
            case .channel:
                try self.handleChannel(message: messageID, user: messageUser, time: messageTime, actionID: actionID, payload: payload)
            default:
                debugger("Ignoring unsupported message type: \(messageType.rawValue)")
                break
            }
        }
    }
    
    internal func handleInbound(message id: String, user: NINChannelUser, time: Double, actionID: Int, payload: NINLowLevelClientPayload) throws {
        try [Int](0..<payload.length()).forEach({ index in
            let decode: Result<ChatMessagePayload> = payload.get(index)!.decode()
            switch decode {
            case .success(let message):
                debugger("Received Chat message with payload: \(message)")
                var hasAttachment = false
                if let files = message.files, files.count > 0 {
                    files.forEach { [unowned self] file in
                        self.sessionSwift.ninchat(self.sessionSwift, didOutputSDKLog: "Got file with MIME type: \(String(describing: file.attributes.type))")
                        let fileInfo = NINFileInfo(fileID: file.id, name: file.attributes.name, mimeType: file.attributes.type, size: file.attributes.size)

                        // Only process certain files at this point
                        guard fileInfo.isImage || fileInfo.isVideo || fileInfo.isPDF else { return }
                        hasAttachment = true
                        fileInfo.updateInfo(session: self) { error, didRefreshNetwork in
                            self.add(message: NINTextMessage(messageID: id, textContent: nil, sender: user, timestamp: Date(timeIntervalSince1970: time), mine: user.userID == self.myUserID, attachment: fileInfo))
                        }
                    }
                }
    
                /// Only allocate a new message now if there is text and no attachment
                if !hasAttachment, !message.text.isEmpty {
                    self.add(message:  NINTextMessage(messageID: id, textContent: message.text, sender: user, timestamp: Date(timeIntervalSince1970: time), mine: user.userID == self.myUserID, attachment: nil))
                }
            case .failure(let error):
                throw error
            }
        })
    }
    
    internal func handleChannel(message id: String, user: NINChannelUser, time: Double, actionID: Int, payload: NINLowLevelClientPayload) throws {
        
        try [Int](0..<payload.length()).forEach { index in
            let decode: Result<ChatMessagePayload> = payload.get(index)!.decode()
            switch decode {
            case .success(let message):
                /// There is no receiver for the decoded payload
                /// TODO: Check the code to find the appropriate usage later
                debugger("Received a Channel message with payload: \(message)")
            case .failure(let error):
                throw error
            }
        }
    }
    
    internal func handleCompose(message id: String, user: NINChannelUser, time: Double, actionID: Int, payload: NINLowLevelClientPayload) throws {
        
        try [Int](0..<payload.length()).forEach { [unowned self] index in
            let decode: Result<ComposeMessagePayload> = payload.get(index)!.decode()
            switch decode {
            case .success(let compose):
                debugger("Received Compose message with payload: \(compose)")
                if let type = compose.element, type == .button, type != .select {
                    /// There is no receiver for the decoded payload
                    /// TODO: Check the code to find the appropriate usage later
                    debugger("Found ui/compose object with unhandled element= \(type), discarding message")
                } else if let msg = NINUIComposeMessage(id: id, sender: user, timestamp: Date(timeIntervalSince1970: time), mine: user.userID == self.myUserID, payload: [compose]) {
                    self.add(message: msg)
                }
            case .failure(let error):
                throw error
            }
        }
    }
    
    internal func handlePart(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload) throws {
        /// TODO: The corresponded model does not exists in `NinchatSDK`
        /// Update to use JSON decode as soon as we find how the function works
        debugger("Received a Part message with payload: \(payload)")
    }
    
    /*
    Event: map[event_id:2 action_id:1 channel_id:5npnrkp1009n error_type:channel_not_found event:error]
    */
    internal func handlerError(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        let error = try param.error()
        
        self.onActionID?(actionID, error)
    }
}
