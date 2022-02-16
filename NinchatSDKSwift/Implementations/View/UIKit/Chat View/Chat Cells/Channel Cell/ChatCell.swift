//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ChatCell: UIView {
    var session: NINChatSessionAttachment? { get set }
    var videoThumbnailManager: VideoThumbnailManager? { get set }
    var onImageTapped: ((_ attachment: FileInfo, _ image: UIImage?) -> Void)? { get set }
    var onComposeSendTapped: ComposeMessageViewProtocol.OnUIComposeSendActionTapped? { get set }
    var onComposeUpdateTapped: ComposeMessageViewProtocol.OnUIComposeUpdateActionTapped? { get set }
}

protocol ChannelCell: UIView {
    var delegate: NINChatSessionInternalDelegate? { get set }
    func populateChannel(message: ChannelMessage, configuration: SiteConfiguration?, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, layerAssets: NINLayerAssetDictionary?, agentAvatarConfig: AvatarConfig?, userAvatarConfig: AvatarConfig?, composeState: [Bool]?)
}
