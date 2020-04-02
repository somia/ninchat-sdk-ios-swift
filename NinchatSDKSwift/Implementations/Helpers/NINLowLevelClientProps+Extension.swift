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
    case requestAudience = "request_audience"
    case sendFile = "send_file"
    case describeFile = "describe_file"
    case partChannel = "part_channel"
    case loadHistory = "load_history"
    case updateMember = "update_member"
    case sendMessage = "send_message"
    case beginICE = "begin_ice"
}

// MARK: - Un-optional initializer

extension NINLowLevelClientProps {
    /// For some unknown reasons, the `NINLowLevelClientProps` initialization is optional
    /// The following variable unwrap it
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
}

protocol NINLowLevelSessionProps {
    var sessionID: NINResult<String> { get }
//    var actionID: Result<Int> { get }
//    var error: Error? { get }
//    var event: Result<String> { get }
    var siteSecret: NINResult<String> { set get }
    var name: NINResult<String> { set get }

    func setAction(_ action: NINLowLevelClientActions)
}

extension NINLowLevelClientProps: NINLowLevelSessionProps {
    var sessionID: NINResult<String> {
        get { self.value(forKey: "session_id") }
    }

    var siteSecret: NINResult<String> {
        get { self.value(forKey: "site_secret") }
        set { self.set(value: newValue.value, forKey: "site_secret") }
    }

    var name: NINResult<String> {
        get { self.value(forKey: "name") }
        set { self.set(value: newValue.value, forKey: "name") }
    }

    func setAction(_ action: NINLowLevelClientActions) {
        self.set(value: action.rawValue, forKey: "action")
    }
}

protocol NINLowLevelQueueProps {
    var queueName: NINResult<String> { get }
    var realmQueue: NINResult<NINLowLevelClientProps> { get }
    var queuePosition: NINResult<Int> { get }
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
        get { self.value(forKey: "realm_queues") }
    }

    var queuePosition: NINResult<Int> {
        get { self.value(forKey: "queue_position") }
    }

    var queueAttributes: NINResult<NINLowLevelClientProps> {
        get { self.value(forKey: "queue_attrs") }
    }

    var queueID: NINResult<String> {
        get { self.value(forKey: "queue_id") }
        set { self.set(value: newValue.value, forKey: "queue_id") }
    }

    var realmID: NINResult<String> {
        get { self.value(forKey: "realm_id") }
        set { self.set(value: newValue.value, forKey: "realm_id") }
    }

    var queuesID: NINResult<NINLowLevelClientStrings> {
        get { self.value(forKey: "queue_ids") }
        set { self.set(value: newValue.value, forKey: "queue_ids") }
    }

    var metadata: NINResult<NINLowLevelClientProps> {
        get { self.value(forKey: "audience_metadata") }
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
        get { self.value(forKey: "channel_members") }
    }

    var channelAttributes: NINResult<NINLowLevelClientProps> {
        get { self.value(forKey: "channel_attrs") }
    }

    var channelClosed: NINResult<Bool> {
        switch self.channelAttributes {
        case .success(let attributes):
            return attributes.value(forKey: "closed")
        case .failure(let error):
            return .failure(error)
        }
    }

    var channelSuspended: NINResult<Bool> {
        switch self.channelAttributes {
        case .success(let attributes):
            return attributes.value(forKey: "suspended")
        case .failure(let error):
            return .failure(error)
        }
    }

    var channelID: NINResult<String> {
        get { self.value(forKey: "channel_id") }
        set { self.set(value: newValue.value, forKey: "channel_id") }
    }

    var channelMemberAttributes: NINResult<NINLowLevelClientProps> {
        get { self.value(forKey: "member_attrs") }
        set { self.set(value: newValue.value, forKey: "member_attrs") }
    }
}

protocol NINLowLevelUserProps {
    var userAuth: NINResult<String> { get }
    var iconURL: NINResult<String> { get }
    var displayName: NINResult<String> { get }
    var realName: NINResult<String> { get }
    var isGuest: NINResult<Bool> { get }

    var userID: NINResult<String> { set get }
    var userAttributes: NINResult<NINLowLevelClientProps> { set get }
}

extension NINLowLevelClientProps: NINLowLevelUserProps {
    var userAuth: NINResult<String> {
        get { self.value(forKey: "user_auth") }
    }

    var iconURL: NINResult<String> {
        get { self.value(forKey: "iconurl") }
    }

    var displayName: NINResult<String> {
        get { self.name }
    }

    var realName: NINResult<String> {
        get { self.value(forKey: "realname") }
    }

    var isGuest: NINResult<Bool> {
        get { self.value(forKey: "guest") }
    }

    var userID: NINResult<String> {
        get { self.value(forKey: "user_id") }
        set { self.set(value: newValue.value, forKey: "user_id") }
    }

    var userAttributes: NINResult<NINLowLevelClientProps> {
        get { self.value(forKey: "user_attrs") }
        set { self.set(value: newValue.value, forKey: "user_attrs") }
    }
}

protocol NINLowLevelMessageProps {
    var messageID: NINResult<String> { get }
    var messageUserID: NINResult<String> { get }
    var messageTime: NINResult<Double> { get }

    var messageType: NINResult<MessageType?> { set get }
    var messageTypes: NINResult<NINLowLevelClientStrings> { set get }
    var writing: NINResult<Bool> { set get }
    var recipients: NINResult<NINLowLevelClientStrings> { set get }
    var messageFold: NINResult<Bool> { set get }
    var messageTTL: NINResult<Int> { set get }
}

extension NINLowLevelClientProps: NINLowLevelMessageProps {
    var messageID: NINResult<String> {
        get { self.value(forKey: "message_id") }
    }

    var messageUserID: NINResult<String> {
        get { self.value(forKey: "message_user_id") }
    }

    var messageTime: NINResult<Double> {
        get { self.value(forKey: "message_time") }
    }

    var messageType: NINResult<MessageType?> {
        get {
            let messageType: NINResult<String>? = self.value(forKey: "message_type")
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
        get { self.value(forKey: "message_types") }
        set { self.set(value: newValue.value, forKey: "message_types") }
    }

    var writing: NINResult<Bool> {
        get { self.value(forKey: "writing") }
        set { self.set(value: newValue.value, forKey: "writing") }
    }

    var recipients: NINResult<NINLowLevelClientStrings> {
        get { self.value(forKey: "message_recipient_ids") }
        set { self.set(value: newValue.value, forKey: "message_recipient_ids") }
    }

    var messageFold: NINResult<Bool> {
        get { self.value(forKey: "message_fold") }
        set { self.set(value: newValue.value, forKey: "message_fold") }
    }

    var messageTTL: NINResult<Int> {
        get { self.value(forKey: "message_ttl") }
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
        get { self.value(forKey: "urls") }
    }

    var stunServers: NINResult<NINLowLevelClientObjects> {
        get { self.value(forKey: "stun_servers") }
    }

    var turnServers: NINResult<NINLowLevelClientObjects> {
        get { self.value(forKey: "turn_servers") }
    }

    var usernameTurnServer: NINResult<String> {
        get { self.value(forKey: "username") }
    }

    var credentialsTurnServer: NINResult<String> {
        get { self.value(forKey: "credential") }
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
        get { self.value(forKey: "file_url") }
    }

    var urlExpiry: NINResult<Date> {
        let expiry: NINResult<Double> = self.value(forKey: "url_expiry")
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
            return attributes.value(forKey: "thumbnail")
        case .failure(let error):
            return .failure(error)
        }
    }

    var thumbnailSize: NINResult<CGSize> {
        switch self.thumbnail {
        case .success(let thumbnail):
            let width: NINResult<Int> = thumbnail.value(forKey: "width")
            let height: NINResult<Int> = thumbnail.value(forKey: "height")

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
        get { self.value(forKey: "file_id") }
        set { self.set(value: newValue.value, forKey: "file_id") }
    }

    var fileAttributes: NINResult<NINLowLevelClientProps> {
        get { self.value(forKey: "file_attrs") }
        set { self.set(value: newValue.value, forKey: "file_attrs") }
    }
}

// MARK: - Properties
/// Fetching the values can result in a `throw`. This is why we are using functions instead of variables

extension NINLowLevelClientProps {
    func error() -> Error? {
        return NinchatError(code: 1, title: self.getString("error_type"))
    }

    public func event() throws -> String {
        return self.getString("event")
    }
    
    // MARK: - ID
    
    func actionID() throws -> Int {
        return try self.getInt("action_id")
    }

    // MARK: - User Attributes
    
    func memberAttributes() throws -> NINLowLevelClientProps {
        return try self.getObject("member_attrs")
    }

    // MARK: - Messages
}

// MARK: - Setters

extension NINLowLevelClientProps {
    // MARK: - Realm queues
    
    // MARK: - File
    
    func setFile(id: String) {
        self.setString("file_id", val: id)
    }
    
    func setFile(attributes: NINLowLevelClientProps) {
        self.setObject("file_attrs", ref: attributes)
    }

    
    // MARK: - Members
    
    func set(member attributes: NINLowLevelClientProps) {
        self.setObject("member_attrs", ref: attributes)
    }
}

// MARK: - Helper

extension NINLowLevelClientProps {
    func value<T>(forKey key: String) -> NINResult<T> {
        do {
            switch T.self {
            case is Int.Type:
                return .success(try self.getInt(key) as! T)
            case is Double.Type:
                return .success(try self.getDouble(key) as! T)
            case is Bool.Type:
                return .success(try self.getBool(key) as! T)
            case is String.Type:
                return .success(try self.getString(for: key) as! T)
            case is NINLowLevelClientProps.Type:
                return .success(try self.getObject(key) as! T)
            case is NINLowLevelClientStrings.Type:
                return .success(try self.getStringArray(key) as! T)
            case is NINLowLevelClientObjects.Type:
                return .success(try self.getObjectArray(key) as! T)
            default:
                fatalError("Error in requested type: \(T.self)")
            }

        } catch {
            return .failure(error)
        }
    }

    func set<T>(value: T, forKey key: String) {
        switch T.self {
        case is Int.Type:
            self.setInt(key, val: (value as! Int))
        case is Double.Type:
            self.setFloat(key, val: (value as! Double))
        case is Bool.Type:
            self.setBool(key, val: (value as! Bool))
        case is String.Type:
            self.setString(key, val: (value as! String))
        case is NINLowLevelClientProps.Type:
            self.setObject(key, ref: (value as! NINLowLevelClientProps))
        case is NINLowLevelClientStrings.Type:
            self.setStringArray(key, ref: (value as! NINLowLevelClientStrings))
        default:
            fatalError("Error in requested type: \(T.self)")
        }
    }

    private func getInt(_ key: String) throws -> Int {
        var value: Int = 0
        try self.getInt(key, val: &value)

        return value
    }

    private func getDouble(_ key: String) throws -> Double {
        var value: Double = 0
        try self.getFloat(key, val: &value)

        return value
    }

    private func getBool(_ key: String) throws -> Bool {
        var value: ObjCBool = false
        try self.getBool(key, val: &value)

        return value.boolValue
    }

    private func getString(_ key: String) -> String {
        return self.getString(key, error: nil)
    }

    private func getString(for key: String) throws -> String {
        var error: AutoreleasingUnsafeMutablePointer<NSError?>?
        let value = self.getString(key, error: error)
        if let err = error as? Error {
            throw err
        }
        return value
    }
}
