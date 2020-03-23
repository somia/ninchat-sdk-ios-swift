//
// Copyright (c) 16.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum Element: String, Codable {
    case select
    case button
}

struct ComposeMessage: ChannelMessage, Equatable {
    // MARK: - ChatMessage
    let timestamp: Date
    let messageID: String

    // MARK: - ChannelMessage
    let mine: Bool
    let sender: ChannelUser
    var series: Bool = false
    
    // MARK: - ComposeMessage
    let content: [ComposeContent]
    var sendPressedIndex: Int {
        self.content.firstIndex(where: { $0.sendPressed ?? false }) ?? -1
    }
}

// MARK: - Equatable
extension ComposeMessage {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.messageID == rhs.messageID
    }
}

/** `ComposeContent` should be defined as a `class` since it passed by reference
 *  Using `struct` results in missing "sent" status of the options.
 */
final class ComposeContent: Codable, Equatable {
    let className, link, id, label, name: String?
    let element: Element
    let options: [ComposeContentOption]?
    var sendPressed: Bool? = false
    
    init(className: String?, link: String?, id: String?, label: String?, name: String?, element: Element, options: [ComposeContentOption]?) {
        self.className = className
        self.link = link
        self.id = id
        self.label = label
        self.name = name
        self.element = element
        self.options = options
        
        self.sendPressed = false
    }
    
    func content(overrideOptions options: [ComposeContentOption]?) -> ComposeContent {
        ComposeContent(className: self.className, link: self.link, id: self.id, label: self.label, name: self.name, element: self.element, options: options ?? self.options)
    }
    
    enum CodingKeys: String, CodingKey {
        case className = "class"
        case element, id, label, name, options
        case link = "href"
        case sendPressed
    }
}

// MARK: - Equatable
extension ComposeContent {
    static func == (lhs: ComposeContent, rhs: ComposeContent) -> Bool {
        lhs.id == rhs.id
    }
}

struct ComposeContentOption: Codable {
    let label, value: String
    var selected: Bool?
}
