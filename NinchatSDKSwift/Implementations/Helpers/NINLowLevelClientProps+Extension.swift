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
             return attributes.value(forKey: "name")
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

// MARK: - Properties
/// Fetching the values can result in a `throw`. This is why we are using functions instead of variables

extension NINLowLevelClientProps {
    func writing() throws -> Bool {
        return try self.getBool("writing")
    }
    
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
    
    func userID() -> String {
        return self.getString("user_id")
    }
    
    func messageID() -> String {
        return self.getString("message_id")
    }

    // MARK: - User Attributes
    
    func memberAttributes() throws -> NINLowLevelClientProps {
        return try self.getObject("member_attrs")
    }
    
    func userAttributes() throws -> NINLowLevelClientProps {
        return try self.getObject("user_attrs")
    }
    
    func userAttributes_IconURL() -> String {
        return self.getString("iconurl")
    }
    
    func userAttributes_DisplayName() -> String {
        return self.getString("name")
    }
    
    func userAttributes_RealName() -> String {
        return self.getString("realname")
    }
    
    func userAttributes_IsGuest() throws -> Bool {
        return try self.getBool("guest")
    }

    // MARK: - File
    
    func fileURL() -> String {
        return self.getString("file_url")
    }
    
    func urlExpiry() throws -> Date {
        let expiry = try self.getDouble("url_expiry")
        return Date(timeIntervalSince1970: expiry)
    }
    
    func fileAttributes_ThumbnailSize() throws -> CGSize {
        let thumbnail = try self.getObject("file_attrs").getObject("thumbnail")
        return CGSize(width: try thumbnail.getInt("width"), height: try thumbnail.getInt("height"))
    }
    
    // MARK: - ICE
    
    func serversURLs() throws -> NINLowLevelClientStrings {
        return try self.getStringArray("urls")
    }
    
    func stunServers() throws -> NINLowLevelClientObjects {
        return try self.getObjectArray("stun_servers")
    }
    
    func turnServers() throws -> NINLowLevelClientObjects {
        return try self.getObjectArray("turn_servers")
    }
    
    func turnServers_UserName() -> String {
        return self.getString("username")
    }
    
    func turnServers_Credential() -> String {
        return self.getString("credential")
    }
    
    // MARK: - Messages
    
    func messageType() -> MessageType? {
        return MessageType(rawValue: self.getString("message_type"))
    }
    
    func messageUserID() -> String {
        return self.getString("message_user_id")
    }
    
    func messageTime() throws -> Double {
        return try self.getDouble("message_time")
    }
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
    
    func set(isWriting: Bool) {
        self.setBool("writing", val: isWriting)
    }
    
    func setUser(id: String) {
        self.setString("user_id", val: id)
    }
    
    func set(member attributes: NINLowLevelClientProps) {
        self.setObject("member_attrs", ref: attributes)
    }
    
    // MARK: - Message
    
    func set(messageType type: String) {
        self.setString("message_type", val: type)
    }
    
    func set(recipients: NINLowLevelClientStrings) {
        self.setStringArray("message_recipient_ids", ref: recipients)
    }
    
    func set(messageFold fold: Bool) {
        self.setBool("message_fold", val: fold)
    }
    
    func set(messageTTL ttl: Int) {
        self.setInt("message_ttl", val: ttl)
    }
    
    // MARK: - Session

    func setUser(attributes: NINLowLevelClientProps) {
        self.setObject("user_attrs", ref: attributes)
    }
    
    func set(messageTypes types: NINLowLevelClientStrings) {
        self.setStringArray("message_types", ref: types)
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