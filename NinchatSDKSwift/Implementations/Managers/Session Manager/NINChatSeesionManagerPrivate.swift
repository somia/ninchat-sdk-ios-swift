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
        delegate?.log(value: "Realm queues found - flushing list of previously available queues.")
        queues.removeAll()
        
        let queuesParser = NINChatClientPropsParser()
        let actionID = try param.actionID()
    
        do {
            let realmQueues = try param.realmQueue()
            try realmQueues.accept(queuesParser)
        
            self.queues = queuesParser.properties.keys.compactMap({ key in
                NINQueue(id: key, andName: try? realmQueues.getObject(key).queueAttributes_Name())
            })
        
            /// Form the list of audience queues; if audienceQueues is specified in siteConfig, we use those;
            /// if not, we use the complete list of queues.
            if let audienceQueueIDs = self.siteConfiguration.audienceQueues {
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
        let queueID = param.queueID()
        do {
            let position = try param.queuePosition()
            if type == .audienceEnqueued {
                guard self.currentQueueID == nil else { throw NINSessionExceptions.hasActiveQueue }
                
                self.currentQueueID = queueID
                self.queueUpdateBoundClosures.values.forEach({ $0(type, queueID, nil) })
            }
            
            if actionID != 0 || type == .queueUpdated {
                self.onProgress?(queueID, position, type, nil)
            }
        } catch {
            self.queueUpdateBoundClosures.values.forEach({ $0(type, queueID, error) })
        }
    }
    
    internal func didUpdateUser(param: NINLowLevelClientProps) throws {
        guard self.currentChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        
        let userID = param.userID()
        self.channelUsers[userID] = parse(userAttr: try param.userAttributes(), userID: userID)
    }
    
    internal func didFindFile(param: NINLowLevelClientProps) throws {
        let thumbnail = try? param.fileAttributes_ThumbnailSize()
        let aspectRatio: Double = (thumbnail != nil) ? Double(thumbnail!.width/thumbnail!.height) : 1.0
            
        let actionID = try param.actionID()
        do {
            let fileURL = param.fileURL()
            let urlExpiry = try param.urlExpiry()
            
            print("expire: \(urlExpiry)")
            
            self.onActionFileInfo?(actionID, ["aspectRatio": aspectRatio, "url": fileURL, "urlExpiry": urlExpiry], nil)
        } catch {
            self.onActionFileInfo?(actionID, nil, error)
        }
    }
    
    internal func didDeleteUser(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        let userID = param.userID()
        if userID == myUserID {
            delegate?.log(value: "Current user deleted.")
        }
        self.onActionID?(actionID, nil)
    }
    
    internal func didJoinChannel(param: NINLowLevelClientProps) throws {
        guard currentQueueID != nil else { throw NINSessionExceptions.noActiveQueue }
        guard currentChannelID == nil else { throw NINSessionExceptions.noActiveChannel }
        
        let channelID = param.channelID()
        delegate?.log(value: "Joined channel ID: \(channelID)")

        /// Set the currently active channel
        self.currentChannelID = channelID
        self.backgroundChannelID = nil

        /// Get the queue we are joining
        let queueName = self.queues.compactMap({ $0 }).filter({ [weak self] queue in
            queue.queueID == self?.currentQueueID }).first?.name ?? ""
        
        /// We are no longer in the queue; clear the queue reference
        self.currentQueueID = nil;

        /// Clear current list of messages and users
        chatMessages.removeAll()
        channelUsers.removeAll()
        
        /// Insert a meta message about the conversation start
        self.add(message: MetaMessage(timestamp: Date(), text: self.translate(key: "Audience in queue {{queue}} accepted.", formatParams: ["queue": queueName]) ?? "", closeChatButtonTitle: nil))
        
        /// Extract the channel members' data
        do {
            let parser = NINChatClientPropsParser()
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
    }
    
    internal func didPartChannel(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        let channelID = param.channelID()
        
        self.onActionChannel?(actionID, channelID)
    }
    
    internal func didUpdateChannel(param: NINLowLevelClientProps) throws {
        guard currentChannelID != nil || backgroundChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        
        let channelID = param.channelID()
        guard channelID == currentChannelID || channelID == backgroundChannelID else {
            debugger("Got channel_updated for wrong channel: \(channelID)")
            return
        }
        
        let channelClosed = try param.channelClosed()
        let channelSuspended = try param.channelSuspended()
        if channelClosed || channelSuspended {
            let text = self.translate(key: "Conversation ended", formatParams: [:])
            let closeTitle = self.translate(key: "Close chat", formatParams: [:])
            self.add(message: MetaMessage(timestamp: Date(), text: text ?? "", closeChatButtonTitle: closeTitle))
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
                stunServersParam.get(index)!
            }).compactMap({ prop -> NINLowLevelClientStrings in
                try prop.serversURLs()
            }).compactMap({ servers -> ([Int], NINLowLevelClientStrings) in
                ([Int](0..<servers.length()), servers)
            }).map({ (indexArray, serversArray) -> [NINWebRTCServerInfo] in
                return indexArray.map { NINWebRTCServerInfo.server(withURL: serversArray.get($0), username: "", credential: "") }
            }).reduce([], +)
            
            /// Parse the TURN server list
            let turnServers = try [Int](0..<turnServersParam.length()).map({ index -> NINLowLevelClientProps in
                turnServersParam.get(index)!
            }).compactMap({ prop -> (NINLowLevelClientStrings, String, String) in
                (try prop.serversURLs(), prop.turnServers_UserName(), prop.turnServers_Credential())
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
   
    internal func parse(userAttr: NINLowLevelClientProps, userID: String) -> ChannelUser? {
        do {
            return ChannelUser(userID: userID, realName: userAttr.userAttributes_RealName(), displayName: userAttr.userAttributes_DisplayName(), iconURL: userAttr.userAttributes_IconURL(), guest: try userAttr.userAttributes_IsGuest())
        } catch {
            return nil
        }
    }
    
    internal func didReceiveMessage(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload) throws {
        let messageType = param.messageType()
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
            let channelID = param.channelID()
            guard channelID == currentChannelID || channelID == backgroundChannelID else {
                self.delegate?.log(value: "Error: Got event for wrong channel: \(channelID)")
                return
            }
            
            let userID = param.userID()
            guard let messageUser = channelUsers[userID] else {
                self.delegate?.log(value: "Update from unknown user: \(userID)")
                return
            }
            
            if userID != myUserID {
                let isWriting = try param.memberAttributes().writing()
                
                /// Check if that user already has a 'writing' message
                let writingMessage = chatMessages.filter({ ($0 as? UserTypingMessage)?.user.userID == userID }).first as? UserTypingMessage
                if isWriting, writingMessage == nil {
                    /// There's no 'typing' message for this user yet, lets create one
                    self.add(message: UserTypingMessage(timestamp: Date(), user: messageUser))
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
    
    internal func add(message: ChatMessage) {
        /// Check if the previous (normal) message was sent by the same user, ie. is the
        /// message part of a series
        if var channelMessage = message as? ChannelMessage {
            /// Guard against the same message getting added multiple times
            /// should only happen if the client makes extraneous load_history calls elsewhere
            guard self.chatMessages.filter({
                ($0 as? ChannelMessage)?.messageID == channelMessage.messageID
            }).count == 0 else { return }
            
            // Find the previous channel message
            if let prevMsg = chatMessages
                .compactMap({ $0 as? TextMessage })
                .sorted(by: { $0.timestamp.compare($1.timestamp) == .orderedAscending })
                .last {
                    channelMessage.series = (prevMsg.sender.userID == channelMessage.sender.userID)
                    
                    let dateDiff = channelMessage.timestamp - prevMsg.timestamp
                    if let minDiff = dateDiff.minute {
                        channelMessage.series = channelMessage.series && minDiff == 0
                    }
            } else {
                channelMessage.series = false
            }
        }
        
        chatMessages.insert(message, at: 0)
        chatMessages.sort {
            if let msg1 = $0 as? ChannelMessage, let msg2 = $1 as? ChannelMessage {
                return msg1.messageID.compare(msg2.messageID) == .orderedDescending
            }
            return $0.timestamp.compare($1.timestamp) == .orderedDescending
        }
        self.onMessageAdded?(chatMessages.firstIndex(where: { $0.asEquatable == message.asEquatable }) ?? -1)
    }
    
    internal func removeMessage(atIndex index: Int) {
        chatMessages.remove(at: index)
        self.onMessageRemoved?(index)
    }
    
    internal func part(channel ID: String, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        let param = NINLowLevelClientProps.initiate
        param.set_partChannel()
        param.setChannel(id: ID)
        
        do {
            let actionID = try session.send(param)
            self.onActionChannel = { id, channelID in
                guard actionID == id else { return }
                completion(nil)
            }
        } catch {
            completion(error)
        }
    }
    
    internal func disconnect() {
        self.delegate?.log(value: "disconnect: Closing Ninchat session.")
        
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
        
        let messageID = param.messageID()
        let messageUserID = param.messageUserID()
        let messageTime = try param.messageTime()
        let messageUser = self.channelUsers[messageUserID]
        
        guard let messageType = param.messageType() else { return }
        switch messageType {
        case .candidate, .answer, .offer, .call, .pickup, .hangup:
            /// This message originates from me; we can ignore it.
            if actionID != 0 { return }
            
            try [Int](0..<payload.length()).forEach { [weak self] index in
                /// Handle a WebRTC signaling message
                let decode: Result<RTCSignal> = payload.get(index)!.decode()
                switch decode {
                case .success(let signal):
                    if  [.offer, .call, .pickup, .hangup].filter({ $0 == messageType }).count > 0 {
                        self?.onRTCSignal?(messageType, messageUser, signal)
                    } else if [.candidate, .answer].filter({ $0 == messageType }).count > 0 {
                        self?.onRTCClientSignal?(messageType, messageUser, signal)
                    }
                case .failure(let error):
                    throw error
                }
            }
        case .text, .file:
            guard messageUser != nil else { return }
            try self.handleInbound(message: messageID, user: messageUser!, time: messageTime, actionID: actionID, payload: payload)
        case .compose:
            guard messageUser != nil else { return }
            try self.handleCompose(message: messageID, user: messageUser!, time: messageTime, actionID: actionID, payload: payload)
        case .channel:
            try self.handleChannel(message: messageID, user: messageUser, time: messageTime, actionID: actionID, payload: payload)
        default:
            debugger("Ignoring unsupported message type: \(messageType.rawValue)")
            break
        }

    }
    
    internal func handleInbound(message id: String, user: ChannelUser, time: Double, actionID: Int, payload: NINLowLevelClientPayload) throws {
        try [Int](0..<payload.length()).forEach({ index in
            let decode: Result<ChatMessagePayload> = payload.get(index)!.decode()
            switch decode {
            case .success(let message):
                debugger("Received Chat message with payload: \(message)")
                var hasAttachment = false
                if let files = message.files, files.count > 0 {
                    files.forEach { [unowned self] file in
                        self.delegate?.log(value: "Got file with MIME type: \(String(describing: file.attributes.type))")
                        let fileInfo = FileInfo(fileID: file.id, name: file.attributes.name, mimeType: file.attributes.type, size: file.attributes.size)
                        hasAttachment = fileInfo.isImage || fileInfo.isVideo || fileInfo.isPDF
                        
                        // Only process certain files at this point
                        guard hasAttachment else { return }
                        fileInfo.updateInfo(session: self) { error, didRefreshNetwork in
                            guard error == nil else { return }
                            
                            self.add(message: TextMessage(timestamp: Date(timeIntervalSince1970: time), messageID: id, mine: user.userID == self.myUserID, sender: user, textContent: nil, attachment: fileInfo))
                        }
                    }
                }
    
                /// Only allocate a new message now if there is text and no attachment
                if let text = message.text, !text.isEmpty, !hasAttachment {
                    self.add(message:  TextMessage(timestamp: Date(timeIntervalSince1970: time), messageID: id, mine: user.userID == self.myUserID, sender: user, textContent: text, attachment: nil))
                }
            case .failure(let error):
                throw error
            }
        })
    }
    
    internal func handleChannel(message id: String, user: ChannelUser?, time: Double, actionID: Int, payload: NINLowLevelClientPayload) throws {
        
        try [Int](0..<payload.length()).forEach { index in
            let decode: Result<ChatChannelPayload> = payload.get(index)!.decode()
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
    
    internal func handleCompose(message id: String, user: ChannelUser, time: Double, actionID: Int, payload: NINLowLevelClientPayload) throws {
        
        try [Int](0..<payload.length()).forEach { [unowned self] index in
            let decode: Result<[ComposeContent]> = payload.get(index)!.decode()
            switch decode {
            case .success(let compose):
                debugger("Received Compose message with payload: \(compose)")
                if compose.filter({ $0.element != .button && $0.element != .select }).count > 0 {
                    debugger("Found ui/compose object with unhandled element, discarding message")
                } else {
                    self.add(message: ComposeMessage(timestamp: Date(timeIntervalSince1970: time), messageID: id, mine: user.userID == self.myUserID, sender: user, content: compose))
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
 
    internal func handlerError(param: NINLowLevelClientProps) throws {
        let actionID = try param.actionID()
        
        self.onActionID?(actionID, param.error())
    }
}
