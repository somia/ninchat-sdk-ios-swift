//
// Copyright (c) 9.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ChatMeta: UIView {
    var delegate: NINChatSessionInternalDelegate? { get set }
    var onCloseChatTapped: ((NINButton) -> Void)? { get set }
    
    func populate(message: MetaMessage, colorAssets: NINColorAssetDictionary?)
}
