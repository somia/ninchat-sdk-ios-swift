//
// Copyright (c) 28.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol TypingCell: UIView {
    func populateTyping(message: UserTypingMessage, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?, agentAvatarConfig: AvatarConfig?)
}

protocol LoadingCell: UIView {
    func populateLoading(agentAvatarConfig: AvatarConfig, imageAssets: NINImageAssetDictionary?, colorAssets: NINColorAssetDictionary?)
}
