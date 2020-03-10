//
// Copyright (c) 21.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

struct ChatChannelPayload: Codable {
    let channelOldAttributes: ChannelAttributes?
    let channelNewAttributes: ChannelAttributes?

    enum CodingKeys: String, CodingKey {
        case channelOldAttributes = "channel_attrs_old"
        case channelNewAttributes = "channel_attrs_new"
    }
}

// MARK: - ChannelAttrsNew
struct ChannelAttributes: Codable {
    let closed: Bool?
    let anonymous: Bool?
    let audienceID: String?
    let disclosed: Bool?
    let disclosedSince: Int?
    let ownerID: String?
    let channelAttrsOldPrivate: Bool?
    let queueID, requesterID, upload: String?

    enum CodingKeys: String, CodingKey {
        case closed, anonymous
        case audienceID = "audience_id"
        case disclosed
        case disclosedSince = "disclosed_since"
        case ownerID = "owner_id"
        case channelAttrsOldPrivate = "private"
        case queueID = "queue_id"
        case requesterID = "requester_id"
        case upload
    }

}
