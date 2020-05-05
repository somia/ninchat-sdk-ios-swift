//
// Copyright (c) 26.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

struct NinchatError: Error {
    let code: Int
    let title: String
}

enum NINLowLevelClientActions: String {
    case deleteUser = "delete_user"
    case describeRealmQueues = "describe_realm_queues"
    case describeQueue = "describe_queue"
    case requestAudience = "request_audience"
    case sendFile = "send_file"
    case describeFile = "describe_file"
    case describeChannel = "describe_channel"
    case partChannel = "part_channel"
    case loadHistory = "load_history"
    case updateMember = "update_member"
    case sendMessage = "send_message"
    case beginICE = "begin_ice"
}

enum HistoryOrder: Int {
    typealias RawValue = Int

    case DESC   = -1    // requests newer messages first
    case ASC    = 1     // requests older messages first
}

extension NINLowLevelClientProps {
    static func initiate(action: NINLowLevelClientActions? = nil, name: String? = nil) -> NINLowLevelClientProps {
        let props = NINLowLevelClientProps()

        if let action = action {
            props?.setAction(action)
        }
        if let name = name {
            props?.name = .success(name)
        }

        return props!
    }

    static func initiate(credentials: NINSessionCredentials) -> NINLowLevelClientProps {
        let props = NINLowLevelClientProps()
        props?.set(value: credentials.userID, forKey: "user_id")
        props?.set(value: credentials.userAuth, forKey: "user_auth")

        return props!
    }

    /**
    * Currently supported value types: String, Int, Double, Bool, NINLowLevelClientProps, NINLowLevelClientStrings, and NINLowLevelClientJSON
    */
    public static func initiate<T>(metadata: [String:T]) -> NINLowLevelClientProps {
        let props = NINLowLevelClientProps()
        for (key,value) in metadata {
            props?.set(value: value, forKey: key)
        }

        return props!
    }
}

protocol NINLowLevelSessionProps {
    var sessionID: NINResult<String> { get }
    var actionID: NINResult<Int> { get }
    var error: Error? { get }
    var event: NINResult<String> { get }
    var siteSecret: NINResult<String> { set get }
    var name: NINResult<String> { set get }

    func setAction(_ action: NINLowLevelClientActions)
}

extension NINLowLevelClientProps: NINLowLevelSessionProps {
    var sessionID: NINResult<String> {
        get { self.get(forKey: "session_id") }
    }

    var actionID: NINResult<Int> {
        get { self.get(forKey: "action_id") }
    }

    var error: Error? {
        let errorType: NINResult<String> = self.get(forKey: "error_type")
        if case let .failure(error) = errorType { return error }
        return NinchatError(code: 1, title: errorType.value)
    }

    public var event: NINResult<String> {
        get { self.get(forKey: "event") }
    }

    var siteSecret: NINResult<String> {
        get { self.get(forKey: "site_secret") }
        set { self.set(value: newValue.value, forKey: "site_secret") }
    }

    var name: NINResult<String> {
        get { self.get(forKey: "name") }
        set { self.set(value: newValue.value, forKey: "name") }
    }

    var closed: NINResult<Bool> {
        get { self.get(forKey: "closed") }
    }

    func setAction(_ action: NINLowLevelClientActions) {
        self.set(value: action.rawValue, forKey: "action")
    }
}

protocol NINLowLevelQueueProps {
    var queueName: NINResult<String> { get }
    var realmQueue: NINResult<NINLowLevelClientProps> { get }
    var queuePosition: NINResult<Int> { get }
    var queueClosed: NINResult<Bool> { get }
    var queueAttributes: NINResult<NINLowLevelClientProps> { get }

    var queueID: NINResult<String> { set get }
    var realmID: NINResult<String> { set get }
    var queuesID: NINResult<NINLowLevelClientStrings> { set get }
    var metadata: NINResult<NINLowLevelClientProps> { set get }
}

extension NINLowLevelClientProps: NINLowLevelQueueProps {
    var queueName: NINResult<String> {
        switch self.queueAttributes {
        case .success(let attributes):
             return attributes.name
        case .failure(let error):
            return .failure(error)
        }
    }

    var realmQueue: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "realm_queues") }
    }

    var queuePosition: NINResult<Int> {
        get { self.get(forKey: "queue_position") }
    }

    var queueClosed: NINResult<Bool> {
        switch self.queueAttributes {
        case .success(let attributes):
            return attributes.closed
        case .failure(let error):
            return .failure(error)
        }
    }

    var queueAttributes: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "queue_attrs") }
    }

    var queueID: NINResult<String> {
        get { self.get(forKey: "queue_id") }
        set { self.set(value: newValue.value, forKey: "queue_id") }
    }

    var realmID: NINResult<String> {
        get { self.get(forKey: "realm_id") }
        set { self.set(value: newValue.value, forKey: "realm_id") }
    }

    var queuesID: NINResult<NINLowLevelClientStrings> {
        get { self.get(forKey: "queue_ids") }
        set { self.set(value: newValue.value, forKey: "queue_ids") }
    }

    var metadata: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "audience_metadata") }
        set { self.set(value: newValue.value, forKey: "audience_metadata") }
    }
}

protocol NINLowLevelChannelProps {
    var channelMembers: NINResult<NINLowLevelClientProps> { get }
    var channelAttributes: NINResult<NINLowLevelClientProps> { get }
    var channelClosed: NINResult<Bool> { get }
    var channelSuspended: NINResult<Bool> { get }

    var channelID: NINResult<String> { set get }
    var channelMemberAttributes: NINResult<NINLowLevelClientProps> { set get }
}

extension NINLowLevelClientProps: NINLowLevelChannelProps {
    var channelMembers: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "channel_members") }
    }

    var channelAttributes: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "channel_attrs") }
    }

    var channelClosed: NINResult<Bool> {
        switch self.channelAttributes {
        case .success(let attributes):
            return attributes.get(forKey: "closed")
        case .failure(let error):
            return .failure(error)
        }
    }

    var channelSuspended: NINResult<Bool> {
        switch self.channelAttributes {
        case .success(let attributes):
            return attributes.get(forKey: "suspended")
        case .failure(let error):
            return .failure(error)
        }
    }

    var channelID: NINResult<String> {
        get { self.get(forKey: "channel_id") }
        set { self.set(value: newValue.value, forKey: "channel_id") }
    }

    var channelMemberAttributes: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "member_attrs") }
        set { self.set(value: newValue.value, forKey: "member_attrs") }
    }
}

protocol NINLowLevelUserProps {
    var userAuth: NINResult<String> { get }
    var iconURL: NINResult<String> { get }
    var displayName: NINResult<String> { get }
    var realName: NINResult<String> { get }
    var isGuest: NINResult<Bool> { get }
    var channels: NINResult<NINLowLevelClientProps> { get }

    var userID: NINResult<String> { set get }
    var userAttributes: NINResult<NINLowLevelClientProps> { set get }
}

extension NINLowLevelClientProps: NINLowLevelUserProps {
    var userAuth: NINResult<String> {
        get { self.get(forKey: "user_auth") }
    }

    var iconURL: NINResult<String> {
        get { self.get(forKey: "iconurl") }
    }

    var displayName: NINResult<String> {
        get { self.name }
    }

    var realName: NINResult<String> {
        get { self.get(forKey: "realname") }
    }

    var isGuest: NINResult<Bool> {
        get { self.get(forKey: "guest") }
    }

    var channels: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "user_channels") }
    }

    var userID: NINResult<String> {
        get { self.get(forKey: "user_id") }
        set { self.set(value: newValue.value, forKey: "user_id") }
    }

    var userAttributes: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "user_attrs") }
        set { self.set(value: newValue.value, forKey: "user_attrs") }
    }
}

protocol NINLowLevelMessageProps {
    var messageID: NINResult<String> { get }
    var messageUserID: NINResult<String> { get }
    var messageTime: NINResult<Double> { get }
    var historyLength: NINResult<Int> { get }
    var historyOrder: NINResult<Int> { set get }

    var messageType: NINResult<MessageType?> { set get }
    var messageTypes: NINResult<NINLowLevelClientStrings> { set get }
    var writing: NINResult<Bool> { set get }
    var recipients: NINResult<NINLowLevelClientStrings> { set get }
    var messageFold: NINResult<Bool> { set get }
    var messageTTL: NINResult<Int> { set get }
}

extension NINLowLevelClientProps: NINLowLevelMessageProps {
    var messageID: NINResult<String> {
        get { self.get(forKey: "message_id") }
    }

    var messageUserID: NINResult<String> {
        get { self.get(forKey: "message_user_id") }
    }

    var messageTime: NINResult<Double> {
        get { self.get(forKey: "message_time") }
    }

    var historyLength: NINResult<Int> {
        get { self.get(forKey: "history_length") }
    }

    var historyOrder: NINResult<Int> {
        get { self.get(forKey: "history_order") }
        set { self.set(value: newValue.value, forKey: "history_order") }
    }

    var messageType: NINResult<MessageType?> {
        get {
            let messageType: NINResult<String>? = self.get(forKey: "message_type")
            if messageType == nil { return .success(nil) }
            
            switch messageType! {
            case .success(let type):
                return .success(MessageType(rawValue: type))
            case .failure(let error):
                return .failure(error)
            }
        }
        set {
            guard let type = newValue.value else { return }
            self.set(value: type.rawValue, forKey: "message_type") 
        }
    }

    var messageTypes: NINResult<NINLowLevelClientStrings> {
        get { self.get(forKey: "message_types") }
        set { self.set(value: newValue.value, forKey: "message_types") }
    }

    var writing: NINResult<Bool> {
        get { self.get(forKey: "writing") }
        set { self.set(value: newValue.value, forKey: "writing") }
    }

    var recipients: NINResult<NINLowLevelClientStrings> {
        get { self.get(forKey: "message_recipient_ids") }
        set { self.set(value: newValue.value, forKey: "message_recipient_ids") }
    }

    var messageFold: NINResult<Bool> {
        get { self.get(forKey: "message_fold") }
        set { self.set(value: newValue.value, forKey: "message_fold") }
    }

    var messageTTL: NINResult<Int> {
        get { self.get(forKey: "message_ttl") }
        set { self.set(value: newValue.value, forKey: "message_ttl") }
    }
}

protocol NINLowLevelICEInfoProps {
    var serversURL: NINResult<NINLowLevelClientStrings> { get }
    var stunServers: NINResult<NINLowLevelClientObjects> { get }
    var turnServers: NINResult<NINLowLevelClientObjects> { get }
    var usernameTurnServer: NINResult<String> { get }
    var credentialsTurnServer: NINResult<String> { get }
}

extension NINLowLevelClientProps: NINLowLevelICEInfoProps {
    var serversURL: NINResult<NINLowLevelClientStrings> {
        get { self.get(forKey: "urls") }
    }

    var stunServers: NINResult<NINLowLevelClientObjects> {
        get { self.get(forKey: "stun_servers") }
    }

    var turnServers: NINResult<NINLowLevelClientObjects> {
        get { self.get(forKey: "turn_servers") }
    }

    var usernameTurnServer: NINResult<String> {
        get { self.get(forKey: "username") }
    }

    var credentialsTurnServer: NINResult<String> {
        get { self.get(forKey: "credential") }
    }
}

protocol NINLowLevelFileInfoProps {
    var fileURL: NINResult<String> { get }
    var urlExpiry: NINResult<Date> { get }
    var thumbnail: NINResult<NINLowLevelClientProps> { get }
    var thumbnailSize: NINResult<CGSize> { get }

    var fileID: NINResult<String> { set get }
    var fileAttributes: NINResult<NINLowLevelClientProps> { set get }
}

extension NINLowLevelClientProps: NINLowLevelFileInfoProps {
    var fileURL: NINResult<String> {
        get { self.get(forKey: "file_url") }
    }

    var urlExpiry: NINResult<Date> {
        let expiry: NINResult<Double> = self.get(forKey: "url_expiry")
        switch expiry {
        case .success(let timeInterval):
            return .success(Date(timeIntervalSince1970: timeInterval))
        case .failure(let error):
            return .failure(error)
        }
    }

    var thumbnail: NINResult<NINLowLevelClientProps> {
        switch self.fileAttributes {
        case .success(let attributes):
            return attributes.get(forKey: "thumbnail")
        case .failure(let error):
            return .failure(error)
        }
    }

    var thumbnailSize: NINResult<CGSize> {
        switch self.thumbnail {
        case .success(let thumbnail):
            let width: NINResult<Int> = thumbnail.get(forKey: "width")
            let height: NINResult<Int> = thumbnail.get(forKey: "height")

            switch (width, height) {
            case (.success(let widthValue), .success(let heightValue)):
                return .success(CGSize(width: widthValue, height: heightValue))
            default:
                return .success(CGSize(width: 1.0, height: 1.0))
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    var fileID: NINResult<String> {
        get { self.get(forKey: "file_id") }
        set { self.set(value: newValue.value, forKey: "file_id") }
    }

    var fileAttributes: NINResult<NINLowLevelClientProps> {
        get { self.get(forKey: "file_attrs") }
        set { self.set(value: newValue.value, forKey: "file_attrs") }
    }
}

// MARK: - Helper

extension NINLowLevelClientProps {
    func get<T>(forKey key: String) -> NINResult<T> {
        do {
            switch T.self {
            case is Int.Type:
                return .success(try self.getInt(key) as! T)
            case is Double.Type:
                return .success(try self.getDouble(key) as! T)
            case is Bool.Type:
                return .success(try self.getBool(key) as! T)
            case is String.Type:
                return .success(try self.getString(key) as! T)
            case is NINLowLevelClientProps.Type:
                return .success(try self.getObject(key) as! T)
            case is NINLowLevelClientStrings.Type:
                return .success(try self.getStringArray(key) as! T)
            case is NINLowLevelClientObjects.Type:
                return .success(try self.getObjectArray(key) as! T)
            default:
                fatalError("Error in requested type: \(T.self) forKey: \(key)")
            }

        } catch {
            return .failure(error)
        }
    }

    func set<T>(value: T, forKey key: String) {
        if let value = value as? Double, floor(value) == value {
            self.setInt(key, val: Int(value))
        } else if let value = value as? Double {
            self.setFloat(key, val: value)
        } else if let value = value as? Int {
            self.setInt(key, val: value)
        } else if let value = value as? Bool {
            self.setBool(key, val: value)
        } else if let value = value as? String {
            self.setString(key, val: value)
        } else if let value = value as? NINLowLevelClientProps {
            self.setObject(key, ref: value)
        } else if let value = value as? NINLowLevelClientStrings {
            self.setStringArray(key, ref: value)
        } else if let value = value as? NINLowLevelClientJSON {
            self.setJSON(key, ref: value)
        } else {
            fatalError("Error in requested type: \(T.self) forKey: \(key)")
        }
    }

    internal func getInt(_ key: String) throws -> Int {
        var value: Int = 0
        try self.getInt(key, val: &value)

        return value
    }

    internal func getDouble(_ key: String) throws -> Double {
        var value: Double = 0
        try self.getFloat(key, val: &value)

        return value
    }

    internal func getBool(_ key: String) throws -> Bool {
        var value: ObjCBool = false
        try self.getBool(key, val: &value)

        return value.boolValue
    }

    internal func getString(_ key: String) throws -> String {
        var error: NSError? = nil
        let value = self.getString(key, error: &error)
        if let err = error {
            throw err as Error
        }
        return value
    }
}
