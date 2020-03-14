//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

protocol ChatCell: UIView {
    var isReloading: Bool! { get set }
    
    var session: NINChatSessionAttachment! { get set }
    var videoThumbnailManager: NINVideoThumbnailManager? { get set }
    var onImageTapped: ((_ attachment: NINFileInfo, _ image: UIImage?) -> Void)? { get set }
    var onComposeSendTapped: ((_ compose: ComposeContentViewProtocol) -> Void)? { get set }
    var onComposeUpdateTapped: ((_ state: [Any]?) -> Void)? { get set }
    var onConstraintsUpdate: (() -> Void)? { get set }
}


protocol ChannelCell: UIView {
    func populateChannel(message: NINChannelMessage, configuration: SiteConfiguration, imageAssets: NINImageAssetDictionary, colorAssets: NINColorAssetDictionary, agentAvatarConfig: NINAvatarConfig, userAvatarConfig: NINAvatarConfig, composeState: [Any]?)
}