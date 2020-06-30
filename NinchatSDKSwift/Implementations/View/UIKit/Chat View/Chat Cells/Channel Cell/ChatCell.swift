//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ChatCell: UIView {
    var isReloading: Bool! { get set }
    
    var session: NINChatSessionAttachment? { get set }
    var videoThumbnailManager: VideoThumbnailManager? { get set }
    var onImageTapped: ((_ attachment: FileInfo, _ image: UIImage?) -> Void)? { get set }
    var onComposeSendTapped: ((_ compose: ComposeContentViewProtocol) -> Void)? { get set }
    var onComposeUpdateTapped: ((_ state: [Bool]?) -> Void)? { get set }
    var onConstraintsUpdate: (() -> Void)? { get set }
}


protocol ChannelCell: UIView {
    func populateChannel(message: ChannelMessage, configuration: SiteConfiguration?, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, agentAvatarConfig: AvatarConfig?, userAvatarConfig: AvatarConfig?, composeState: [Bool]?)
}
