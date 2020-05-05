//
// Copyright (c) 28.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

// MARK: - Private helper functions - delegates

extension NINChatSessionManagerImpl {
    internal func didFindRealmQueues(param: NINLowLevelClientProps) throws {
        delegate?.log(value: "Realm queues found - flushing list of previously available queues.")
        queues.removeAll()

        let actionID = param.actionID
        do {
            if case let .failure(error) = param.realmQueue { throw error }

            let queuesParser = NINChatClientPropsParser()
            let realmQueues = param.realmQueue.value
            try realmQueues.accept(queuesParser)

            self.queues = queuesParser.properties.keys.compactMap({ key in
                if let queue = try? realmQueues.getObject(key), case let .success(queueName) = queue.queueName, case let .success(queueClosed) = queue.queueClosed {
                    return Queue(queueID: key, name: queueName, isClosed: queueClosed)
                }
                return nil
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

    internal func didUpdateQueue(type: Events, param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.queueID { throw error }
        guard let queue = self.queues.first(where: { $0.queueID == param.queueID.value }) else { return }

        if case let .failure(error) = param.queuePosition {
            self.queueUpdateBoundClosures.values.forEach({ $0(type, queue, error) }); return
        }
        let position = param.queuePosition.value
        if type == .audienceEnqueued {
            guard self.currentQueueID == nil else { throw NINSessionExceptions.hasActiveQueue }

            self.currentQueueID = queue.queueID
            self.queueUpdateBoundClosures.values.forEach({ $0(type, queue, nil) })
        }
        self.onProgress?(queue, position, type, nil)
    }
    
    internal func didUpdateUser(param: NINLowLevelClientProps) throws {
        guard self.currentChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        if case let .failure(error) = param.userID { throw error }
        if case let .failure(error) = param.userAttributes { throw error }

        parse(userAttr: param.userAttributes.value, userID: param.userID.value)
    }
    
    internal func didFindFile(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.fileURL { throw error }
        var fileInfoDictionary: [String:AnyHashable] = ["url": param.fileURL.value, "aspectRatio": 1, "urlExpiry": Date()]

        if case let .success(expire) = param.urlExpiry {
            fileInfoDictionary["urlExpiry"] = expire
        }

        if case let .success(size) = param.thumbnailSize {
            fileInfoDictionary["aspectRatio"] = Double(size.width/size.height)
        }

        self.onActionFileInfo?(param.actionID, fileInfoDictionary, nil)
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
        if case let .failure(error) = param.channelID { throw error }
        self.didJoinChannel(channelID: param.channelID.value)

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

    internal func didJoinChannel(channelID: String) {
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
        /// If only the previous channel was successfully closed.
        if self.channelClosed {
            chatMessages.removeAll()
            channelUsers.removeAll()
        }

        /// Insert a meta message about the conversation start
        self.add(message: MetaMessage(timestamp: Date(), messageID: self.chatMessages.first?.messageID, text: self.translate(key: "Audience in queue {{queue}} accepted.", formatParams: ["queue": queueName]) ?? "", closeChatButtonTitle: nil))

    }
    
    internal func didPartChannel(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.channelID { throw error }
        
        /// The channel is not actually "closed", it is parted.
        self.channelClosed = false
        self.onActionChannel?(param.actionID, param.channelID.value)
    }
    
    internal func didUpdateChannel(param: NINLowLevelClientProps) throws {
        guard currentChannelID != nil || backgroundChannelID != nil else { throw NINSessionExceptions.noActiveChannel }
        if case let .failure(error) = param.channelID { throw error }

        let channelID = param.channelID.value
        guard channelID == currentChannelID || channelID == backgroundChannelID else {
            debugger("Got channel_updated for wrong channel: \(channelID)"); return
        }

        self.channelClosed = param.channelClosed.value || param.channelSuspended.value
        /// In case of "channel transfer", the corresponded function: "didPartChannel(param:)" is called after this function.
        /// Thus, We will send meta message only if the channel was actually closed, not parted.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard self.channelClosed else { return }

            let text = self.translate(key: Constants.kConversationEnded.rawValue, formatParams: [:])
            let closeTitle = self.translate(key: Constants.kCloseChatText.rawValue, formatParams: [:])
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
            if case let .failure(error) = prop.serversURL { throw error }
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
            if case let .failure(error) = prop.serversURL { throw error }
            if case let .failure(error) = prop.usernameTurnServer { throw error }
            if case let .failure(error) = prop.credentialsTurnServer { throw error }

            return (prop.serversURL.value, prop.usernameTurnServer.value, prop.credentialsTurnServer.value)
        }).compactMap({ (servers, userName, credential) -> ([Int], NINLowLevelClientStrings, String, String) in
            ([Int](0..<servers.length()), servers, userName, credential)
        }).map({ (indexArray, serversArray, userName, credential) -> [WebRTCServerInfo] in
            indexArray.map { WebRTCServerInfo(url: serversArray.get($0), username: userName, credential: credential) }
        }).reduce([], +)

        self.onActionSevers?(param.actionID, stunServers, turnServers)
    }

    internal func didLoadHistory(param: NINLowLevelClientProps) throws {
        if case let .failure(error) = param.historyLength { throw error }
        if param.historyLength.value > 0 {
            self.expectedHistoryLength = param.historyLength.value
        }
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
                let writingMessage = chatMessages.filter({ ($0 as? UserTypingMessage)?.user?.userID == userID }).first as? UserTypingMessage
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
    
    internal func add(message: ChatMessage, remained: NINResult<Int>? = .success(0)) {
        /// Guard against the same message getting added multiple times
        if self.chatMessages.contains(where: { $0.messageID == message.messageID }) { return }
        chatMessages.insert(message, at: 0)

        if self.expectedHistoryLength == self.chatMessages.filter({ $0 is ChannelMessage }).count {
            /// We are loading a history that needs to `reload` corresponded chat view
            self.chatMessages = self.sortAndMap()
            self.onHistoryLoaded?(self.expectedHistoryLength)
            self.expectedHistoryLength = -1

        } else if self.expectedHistoryLength == -1, case let .success(length) = remained, length == 0 {
            /// We are not waiting for a history result
            /// Thus, we will update the view with the index of received message
            self.chatMessages = self.sortAndMap()
            self.onMessageAdded?(chatMessages.firstIndex(where: { $0.asEquatable == message.asEquatable }) ?? -1)
        }
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
            self.bindChannel(action: actionID, closure: completion)
        } catch {
            completion(error)
        }
    }
    
    internal func disconnect() {
        self.delegate?.log(value: "disconnect: Closing Ninchat session.")
        
        self.currentChannelID = nil
        self.backgroundChannelID = nil
        self.currentQueueID = nil
        
        self.session?.close()
        self.session = nil
    }

    internal func parse(userAttr: NINLowLevelUserProps, userID: String) {
        /// TODO: Add result checking for attributes to avoid fatal error
        self.channelUsers[userID] = ChannelUser(userID: userID, realName: userAttr.realName.value, displayName: userAttr.displayName.value, iconURL: userAttr.iconURL.value, guest: userAttr.isGuest.value)
    }

    internal func sortAndMap() -> [ChatMessage] {
        self.chatMessages.sort { $0.messageID > $1.messageID }
        return self.chatMessages.map { message in
            if var msg = message as? ChannelMessage, let msgIndex = self.chatMessages.firstIndex(where: { $0.asEquatable == msg.asEquatable }), msgIndex < self.chatMessages.count - 1, let prevMsg = self.chatMessages[msgIndex + 1] as? ChannelMessage {
                msg.series = (msg.sender?.userID == prevMsg.sender?.userID) && (msg.timestamp.minute == prevMsg.timestamp.minute)
                return msg
            }
            return message
        }
    }

    /** Determines if it is possible to resume the session in case it is still alive. */
    internal func canResumeSession(param: NINLowLevelClientProps) -> Bool {
        if case .failure = param.channels { return false }
        let userChannels = param.channels.value

        do {
            let parser = NINChatClientPropsParser()
            try userChannels.accept(parser)
            parser.properties.keys.forEach {
                let channel: NINResult<NINLowLevelClientProps> = userChannels.get(forKey: $0)
                if case .failure = channel { return }

                /// Extract target channel
                if case .failure = channel.value.channelClosed { return }
                if !channel.value.channelClosed.value {
                    self.currentChannelID = $0

                    /// Extract target queue
                    if case .failure = channel.value.channelAttributes { return}
                    if case .failure = channel.value.channelAttributes.value.queueID { return }
                    self.currentQueueID = channel.value.channelAttributes.value.queueID.value
                }

                /// Extract target realm
                if case .failure = channel.value.realmID { return }
                self.realmID = channel.value.realmID.value
            }

            /// Check if target queue and target channels are found
            return self.currentChannelID != nil && self.currentQueueID != nil && self.realmID != nil
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
            try self.handleInbound(message: messageID, user: messageUser, time: messageTime, actionID: actionID, remained: param.historyLength, payload: payload)
        case .compose:
            try self.handleCompose(message: messageID, user: messageUser, time: messageTime, actionID: actionID, remained: param.historyLength, payload: payload)
        case .channel:
            try self.handleChannel(message: messageID, user: messageUser, time: messageTime, actionID: actionID, remained: param.historyLength, payload: payload)
        default:
            debugger("Ignoring unsupported message type: \(messageType.rawValue)")
            if self.expectedHistoryLength > 0 {
                self.expectedHistoryLength -= 1
            }
        }

    }
    
    internal func handleInbound(message id: String, user: ChannelUser?, time: Double, actionID: Int, remained: NINResult<Int>, payload: NINLowLevelClientPayload) throws {
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
                            
                            self.add(message: TextMessage(timestamp: Date(timeIntervalSince1970: time), messageID: id, mine: user?.userID == self.myUserID, sender: user, textContent: nil, attachment: fileInfo), remained: remained)
                        }
                    }
                }
    
                /// Only allocate a new message now if there is text and no attachment
                if let text = message.text, !text.isEmpty, !hasAttachment {
                    self.add(message:  TextMessage(timestamp: Date(timeIntervalSince1970: time), messageID: id, mine: user?.userID == self.myUserID, sender: user, textContent: text, attachment: nil), remained: remained)
                }
            case .failure(let error):
                throw error
            }
        })
    }
    
    internal func handleChannel(message id: String, user: ChannelUser?, time: Double, actionID: Int, remained: NINResult<Int>, payload: NINLowLevelClientPayload) throws {
        
        try [Int](0..<payload.length()).forEach { index in
            let decode: NINResult<ChatChannelPayload> = payload.get(index)!.decode()
            switch decode {
            case .success(let message):
                debugger("Received a Channel message with payload: \(message)")
            case .failure(let error):
                throw error
            }
        }
    }
    
    internal func handleCompose(message id: String, user: ChannelUser?, time: Double, actionID: Int, remained: NINResult<Int>, payload: NINLowLevelClientPayload) throws {
        
        try [Int](0..<payload.length()).forEach { [unowned self] index in
            let decode: NINResult<[ComposeContent]> = payload.get(index)!.decode()
            switch decode {
            case .success(let compose):
                debugger("Received Compose message with payload: \(compose)")
                if compose.filter({ $0.element != .button && $0.element != .select }).count > 0 {
                    debugger("Found ui/compose object with unhandled element, discarding message")
                } else {
                    self.add(message: ComposeMessage(timestamp: Date(timeIntervalSince1970: time), messageID: id, mine: user?.userID == self.myUserID, sender: user, content: compose), remained: remained)
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
