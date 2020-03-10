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

// MARK: - Un-optional initializer

extension NINLowLevelClientProps {
    /// For some unknown reasons, the `NINLowLevelClientProps` initialization is optional
    /// The following variable unwrap it
    static var initiate: NINLowLevelClientProps {
        NINLowLevelClientProps()!
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
    
    func queueID() -> String {
        return self.getString("queue_id")
    }
    
    func channelID() -> String {
        return self.getString("channel_id")
    }
    
    func userID() -> String {
        return self.getString("user_id")
    }
    
    func messageID() -> String {
        return self.getString("message_id")
    }
    
    // MARK: - Queues
    
    func realmQueue() throws -> NINLowLevelClientProps {
        return try self.getObject("realm_queues")
    }
    
    func queuePosition() throws -> Int {
        return try self.getInt("queue_position")
    }
    
    func queueAttributes_Name() throws -> String {
        return try self.getObject("queue_attrs").getString("name")
    }
    
    // MARK: - Channels
    
    func channelMembers() throws -> NINLowLevelClientProps {
        return try self.getObject("channel_members")
    }
        
    func channelClosed() throws -> Bool {
        return try self.getObject("channel_attrs").getBool("closed")
    }
    
    func channelSuspended() throws -> Bool {
        return try self.getObject("channel_attrs").getBool("suspended")
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
    
    func srversURLs() throws -> NINLowLevelClientStrings {
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
    func set_deleteUser() {
        self.setString("action", val: "delete_user")
    }
    
    func set(name: String) {
        self.setString("name", val: name)
    }
    
    // MARK: - Realm queues
    
    func set_realmQueues() {
        self.setString("action", val: "describe_realm_queues")
    }
    
    func set(realmID id: String) {
        self.setString("realm_id", val: id)
    }
    
    func set(queues id: NINLowLevelClientStrings) {
        self.setStringArray("queue_ids", ref: id)
    }
    
    func set_requestAudience() {
        self.setString("action", val: "request_audience")
    }
    
    func set(queue id: String) {
        self.setString("queue_id", val: id)
    }
    
    func set(metadata data: NINLowLevelClientProps) {
        self.setObject("audience_metadata", ref: data)
    }
    
    // MARK: - File
    
    func set_sendFile() {
        self.setString("action", val: "send_file")
    }
    
    func set_describeFile() {
        self.setString("action", val: "describe_file")
    }
    
    func set(file id: String) {
        self.setString("file_id", val: id)
    }
    
    func set(file attributes: NINLowLevelClientProps) {
        self.setObject("file_attrs", ref: attributes)
    }
    
    // MARK: - Channel
    
    func set_partChannel() {
        self.setString("action", val: "part_channel")
    }
    
    func set(channel id: String) {
        self.setString("channel_id", val: id)
    }
    
    func set_loadHistory() {
        self.setString("action", val: "load_history")
    }
    
    // MARK: - Members
    
    func set_updateMember() {
        self.setString("action", val: "update_member")
    }
    
    func set(isWriting: Bool) {
        self.setBool("writing", val: isWriting)
    }
    
    func set(user id: String) {
        self.setString("user_id", val: id)
    }
    
    func set(member attributes: NINLowLevelClientProps) {
        self.setObject("member_attrs", ref: attributes)
    }
    
    // MARK: - Message
    
    func set_sendMessage() {
        self.setString("action", val: "send_message")
    }
    
    func set(messageType type: String) {
        self.setString("message_type", val: type)
    }
    
    func set(recipients: NINLowLevelClientStrings) {
        self.setStringArray("message_recipient_ids", ref: recipients)
    }
    
    func set(message fold: Bool) {
        self.setBool("message_fold", val: fold)
    }
    
    func set(message ttl: Int) {
        self.setInt("message_ttl", val: ttl)
    }
    
    // MARK: - ICE
    
    func set_beginICE() {
        self.setString("action", val: "begin_ice")
    }
    
    // MARK: - Session
    
    func set(site secret: String) {
        self.setString("site_secret", val: secret)
    }
    
    func set(user attributes: NINLowLevelClientProps) {
        self.setObject("user_attrs", ref: attributes)
    }
    
    func set(message types: NINLowLevelClientStrings) {
        self.setStringArray("message_types", ref: types)
    }
}

// MARK: - Helper

extension NINLowLevelClientProps {
    func getInt(_ key: String) throws -> Int {
        var value: Int = 0
        try self.getInt(key, val: &value)
        
        return value
    }
    
    func getDouble(_ key: String) throws -> Double {
        var value: Double = 0
        try self.getFloat(key, val: &value)
        
        return value
    }
    
    func getBool(_ key: String) throws -> Bool {
        var value: ObjCBool = false
        try self.getBool(key, val: &value)
        
        return value.boolValue
    }
    
    func getString(_ key: String) -> String {
        return self.getString(key, error: nil)
    }
}
