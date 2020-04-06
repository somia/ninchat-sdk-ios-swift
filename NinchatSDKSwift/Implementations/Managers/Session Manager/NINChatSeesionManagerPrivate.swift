//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

// MARK: - Private helper functions - delegates

extension NINChatSessionManagerImpl {
    internal func didRealmQueuesFind(param: NINLowLevelClientProps) throws {
        /// Clear existing queue list
        delegate?.log(value: "Realm queues found - flushing list of previously available queues.")
        queues.removeAll()
        
        let queuesParser = NINChatClientPropsParser()
        let actionID = param.actionID
    
        do {
            if case let .failure(error) = param.realmQueue { throw error }

            let realmQueues = param.realmQueue.value
            try realmQueues.accept(queuesParser)
        
            self.queues = queuesParser.properties.keys.compactMap({ key in
                Queue(queueID: key, name: (try? realmQueues.getObject(key).queueName.value) ?? "")
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
        if case let .failure(error) = param.queueID { throw error }
        let queueID = param.queueID.value

        if case let .failure(error) = param.queuePosition {
            self.queueUpdateBoundClosures.values.forEach({ $0(type, queueID, error) })
        }
        let position = param.queuePosition.value
        if type == .audienceEnqueued {
            guard self.currentQueueID == nil else { throw NINSessionExceptions.hasActiveQueue }

            self.currentQueueID = queueID
            self.queueUpdateBoundClosures.values.forEach({ $0(type, queueID, nil) })
        }

        if case let .failure(error) = param.actionID { throw error }
        let actionID = param.actionID.value
        if actionID != 0 || type == .queueUpdated {
            self.onProgress?(queueID, position, type, nil)
        }
    }
    
    internal func didUpdateUser(param: NINLowLevelClientProps) throws {
        guard self.currentChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        if case let .failure(error) = param.userID { throw error }
        if case let .failure(error) = param.userAttributes { throw error }

        parse(userAttr: param.userAttributes.value, userID: param.userID.value)
    }
    
    internal func didFindFile(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.fileURL { throw error }
        if case let .failure(error) = param.urlExpiry { throw error }
        if case let .failure(error) = param.thumbnailSize { throw error }

        self.onActionFileInfo?(param.actionID, ["aspectRatio": Double(param.thumbnailSize.value.width/param.thumbnailSize.value.height), "url": param.fileURL.value, "urlExpiry": param.urlExpiry.value], nil)
    }
    
    internal func didDeleteUser(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.userID { throw error }

        let userID = param.userID.value
        if userID == myUserID {
            delegate?.log(value: "Current user deleted.")
        }

        self.onActionID?(param.actionID, nil)
    }
    
    internal func didJoinChannel(param: NINLowLevelClientProps) throws {
        guard currentQueueID != nil else { throw NINSessionExceptions.noActiveQueue }
        guard currentChannelID == nil else { throw NINSessionExceptions.noActiveChannel }
        if case let .failure(error) = param.channelID { throw error }

        let channelID = param.channelID.value
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
        /// This is the first message in the conversation with id: 0
        self.add(message: MetaMessage(timestamp: Date(), messageID: nil, text: self.translate(key: "Audience in queue {{queue}} accepted.", formatParams: ["queue": queueName]) ?? "", closeChatButtonTitle: nil))
        
        /// Extract the channel members' data
        if case let .failure(error) = param.channelMembers { throw error }
        do {
            let parser = NINChatClientPropsParser()
            try param.channelMembers.value.accept(parser)
            
            parser.properties.compactMap({ dict in
                        (dict.key, dict.value) as? (String,NINLowLevelClientProps)
                    })
                    .map({ key, value in
                        (key, value.userAttributes.value)
                    }).forEach({ [weak self] userID, attributes in
                self?.parse(userAttr: attributes, userID: userID)
            })
        } catch {
            debugger(error.localizedDescription)
        }
        
        /// Signal channel join event to the asynchronous listener
        self.onChannelJoined?()
    }
    
    internal func didPartChannel(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.channelID { throw error }
        self.onActionChannel?(param.actionID, param.channelID.value)
    }
    
    internal func didUpdateChannel(param: NINLowLevelClientProps) throws {
        guard currentChannelID != nil || backgroundChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        if case let .failure(error) = param.channelID { throw error }

        let channelID = param.channelID.value
        guard channelID == currentChannelID || channelID == backgroundChannelID else {
            debugger("Got channel_updated for wrong channel: \(channelID)"); return
        }

        if case let .failure(error) = param.channelClosed { throw error }
        if case let .failure(error) = param.channelSuspended { throw error }
        if param.channelClosed.value || param.channelSuspended.value {
            let text = self.translate(key: "Conversation ended", formatParams: [:])
            let closeTitle = self.translate(key: "Close chat", formatParams: [:])
            self.add(message: MetaMessage(timestamp: Date(), messageID: self.chatMessages.first?.messageID, text: text ?? "", closeChatButtonTitle: closeTitle))
            self.onChannelClosed?()
        }
    }

    internal func didFindChannel(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.channelID { throw error }
        guard param.channelID.value == self.currentChannelID else { throw NINSessionExceptions.noActiveChannel }

        if case let .failure(error) = param.channelMembers { throw error }
        let memberParser = NINChatClientPropsParser()
        try param.channelMembers.value.accept(memberParser)


        memberParser.properties.keys.forEach { [weak self] userID in
            if let member = memberParser.properties[userID] as? NINLowLevelClientProps, case let .success(attributes) = member.userAttributes {
                self?.parse(userAttr: attributes, userID: userID)
            }
        }
        self.onActionID?(param.actionID, nil)
    }

    /// Processes the response to the WebRTC connectivity ICE query
    internal func didBeginICE(param: NINLowLevelClientProps) throws {

        /// Parse the STUN server list
        if case let .failure(error) = param.stunServers { throw error }
        let stunServersParam = param.stunServers.value
        let stunServers = try [Int](0..<stunServersParam.length()).map({ index -> NINLowLevelClientProps in
            stunServersParam.get(index)!
        }).compactMap({ prop -> NINLowLevelClientStrings in
            if case let .failure(error) = param.serversURL { throw error }
            return prop.serversURL.value
        }).compactMap({ servers -> ([Int], NINLowLevelClientStrings) in
            ([Int](0..<servers.length()), servers)
        }).map({ (indexArray, serversArray) -> [WebRTCServerInfo] in
            indexArray.map { WebRTCServerInfo(url: serversArray.get($0), username: nil, credential: nil) }
        }).reduce([], +)


        /// Parse the TURN server list
        if case let .failure(error) = param.turnServers { throw error }
        let turnServersParam = param.turnServers.value
        let turnServers = try [Int](0..<turnServersParam.length()).map({ index -> NINLowLevelClientProps in
            turnServersParam.get(index)!
        }).compactMap({ prop -> (NINLowLevelClientStrings, String, String) in
            if case let .failure(error) = param.serversURL { throw error }
            if case let .failure(error) = param.usernameTurnServer { throw error }
            if case let .failure(error) = param.credentialsTurnServer { throw error }

            return (prop.serversURL.value, param.usernameTurnServer.value, param.credentialsTurnServer.value)
        }).compactMap({ (servers, userName, credential) -> ([Int], NINLowLevelClientStrings, String, String) in
            ([Int](0..<servers.length()), servers, userName, credential)
        }).map({ (indexArray, serversArray, userName, credential) -> [WebRTCServerInfo] in
            indexArray.map { WebRTCServerInfo(url: serversArray.get($0), username: userName, credential: credential) }
        }).reduce([], +)

        self.onActionSevers?(param.actionID, stunServers, turnServers)
    }
   
    internal func parse(userAttr: NINLowLevelUserProps, userID: String) {
        /// TODO: Add result checking for attributes to avoid fatal error
        self.channelUsers[userID] = ChannelUser(userID: userID, realName: userAttr.realName.value, displayName: userAttr.displayName.value, iconURL: userAttr.iconURL.value, guest: userAttr.isGuest.value)
    }
    
    internal func didReceiveMessage(param: NINLowLevelClientProps, payload: NINLowLevelClientPayload) throws {
        if case let .failure(error) = param.messageType { throw error }
        debugger("Received message of type \(String(describing: param.messageType.value))")

        /// handle transfers
        if param.messageType.value == .part {
            try self.handlePart(param: param, payload: payload); return
        }
        
        guard currentChannelID != nil || backgroundChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        if case let .failure(error) = param.actionID { throw error }
        let actionID = param.actionID

        do {
            try self.handleInbound(param: param, actionID: actionID.value, payload: payload)
            if actionID.value != 0 { self.onActionID?(actionID, nil) }
        } catch {
            if actionID.value != 0 { self.onActionID?(actionID, error) }
        }
    }
    
    internal func didUpdateMember(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.channelID { throw error }

        let actionID = param.actionID
        do {
            let channelID = param.channelID.value
            guard channelID == currentChannelID || channelID == backgroundChannelID else {
                self.delegate?.log(value: "Error: Got event for wrong channel: \(channelID)"); return
            }

            if case let .failure(error) = param.userID { throw error }
            let userID = param.userID.value
            guard let messageUser = channelUsers[userID] else {
                self.delegate?.log(value: "Update from unknown user: \(userID)"); return
            }
            
            if userID != myUserID {
                if case let .failure(error) = param.channelMemberAttributes { throw error }
                if case let .failure(error) = param.channelMemberAttributes.value.writing { throw error }
                let isWriting = param.channelMemberAttributes.value.writing.value
                
                /// Check if that user already has a 'writing' message
                let writingMessage = chatMessages.filter({ ($0 as? UserTypingMessage)?.user.userID == userID }).first as? UserTypingMessage
                if isWriting, writingMessage == nil {
                    /// There's no 'typing' message for this user yet, lets create one
                    self.add(message: UserTypingMessage(timestamp: Date(), messageID: self.chatMessages.first?.messageID, user: messageUser))
                } else if let msg = writingMessage, let index = chatMessages.firstIndex(where: { $0.asEquatable == msg.asEquatable }) {
                    /// There's a 'typing' message for this user - lets remove that.
                    self.removeMessage(atIndex: index)
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
        let param = NINLowLevelClientProps.initiate(action: .deleteUser)
        
        do {
            let actionID = try session.send(param)
            self.bind(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
    
    internal func add(message: ChatMessage) {
        var message = message

        /// Guard against the same message getting added multiple times
        /// should only happen if the client makes extraneous load_history calls elsewhere
        if self.chatMessages.contains(where: { $0.messageID == message.messageID }) { return }
        self.applySeriesStatus(to: &message)
        
        chatMessages.insert(message, at: 0)
        chatMessages.sort { $0.messageID > $1.messageID }
        self.onMessageAdded?(chatMessages.firstIndex(where: { $0.asEquatable == message.asEquatable }) ?? -1)
    }
    
    internal func removeMessage(atIndex index: Int) {
        chatMessages.remove(at: index)
        self.onMessageRemoved?(index)
    }
    
    internal func part(channel ID: String, completion: @escaping CompletionWithError) throws {
        guard let session = self.session else { throw NINSessionExceptions.noActiveSession }
        let param = NINLowLevelClientProps.initiate(action: .partChannel)
        param.channelID = .success(ID)
        
        do {
            let actionID = try session.send(param)
            self.onActionChannel = { result, channelID in
                guard case let .success(id) = result, actionID == id else { return }
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

    internal func applySeriesStatus(to message: inout ChatMessage) {
        guard var channelMessage = message as? ChannelMessage else { return }

        /// Find the previous channel message
        if let prevMsg = self.chatMessages.compactMap({ $0 as? ChannelMessage }).sorted(by: { $0.messageID.compare($1.messageID) == .orderedAscending }).last {
            channelMessage.series = (channelMessage.sender.userID == prevMsg.sender.userID)

            if let minDiff = (channelMessage.timestamp - prevMsg.timestamp).minute {
                channelMessage.series = (channelMessage.series && minDiff == 0)
            }
        }
        message = channelMessage
    }

    /** Determines if it is possible to resume the session in case it is still alive. */
    internal func canResumeSession(param: NINLowLevelClientProps) -> Bool {
        if case .failure = param.channels { return false }
        let userChannels = param.channels.value

        do {
            let channelParser = NINChatClientPropsParser()
            try userChannels.accept(channelParser)

            return channelParser.properties.keys.filter {
                let channel: NINResult<NINLowLevelClientProps> = userChannels.value(forKey: $0)
                if case .failure = channel { return false }
                if case .failure = channel.value.channelClosed { return false }

                if !channel.value.channelClosed.value {
                    self.currentChannelID = $0
                    return true
                }
                return false
            }.count > 0
        } catch {
            return false
        }
    }
}

// MARK: - Private helper functions - handlers

extension NINChatSessionManagerImpl {
    internal func handleInbound(param: NINLowLevelClientProps, actionID: Int, payload: NINLowLevelClientPayload) throws {
        if case let .failure(error) = param.messageID { throw error }
        if case let .failure(error) = param.messageUserID { throw error }
        if case let .failure(error) = param.messageTime { throw error }
        if case let .failure(error) = param.messageType { throw error }

        let messageID = param.messageID.value
        let messageUserID = param.messageUserID.value
        let messageTime = param.messageTime.value
        let messageUser = self.channelUsers[messageUserID]

        guard let messageType = param.messageType.value else { return }
        switch messageType {
        case .candidate, .answer, .offer, .call, .pickup, .hangup:
            /// This message originates from me; we can ignore it.
            if actionID != 0 { return }
            
            try [Int](0..<payload.length()).forEach { [weak self] index in
                /// Handle a WebRTC signaling message
                let decode: NINResult<RTCSignal> = payload.get(index)!.decode()
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
            let decode: NINResult<ChatMessagePayload> = payload.get(index)!.decode()
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
            let decode: NINResult<ChatChannelPayload> = payload.get(index)!.decode()
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
            let decode: NINResult<[ComposeContent]> = payload.get(index)!.decode()
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
        self.onActionID?(param.actionID, param.error)
    }
}
