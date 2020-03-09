//
// Copyright (c) 29.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

class ChatChannelComposeCell: ChatChannelOthersCell {
    
    override var onComposeSendTapped: ((NINComposeContentView) -> Void)? {
        set {
            self.composeMessageView.uiComposeSendPressedCallback = { compose in
                newValue?(compose!)
            }
        }
        get {
            self.composeMessageView.uiComposeSendPressedCallback
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var composeMessageView: NINComposeMessageView!
    
    // MARK: - UITableViewCell life-cycle
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.onComposeSendTapped = nil
        self.composeMessageView.clear()
    }
    
    func populateCompose(message: NINUIComposeMessage, configuration: NINSiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Any]?) {
        self.composeMessageView.uiComposeStateUpdateCallback = { [weak self] composeStates in
            self?.onComposeUpdateTapped?(composeStates)
        }
        self.composeMessageView.populate(with: message, siteConfiguration: configuration, colorAssets: Dictionary(uniqueKeysWithValues: colorAssets.map { ($0.key.rawValue, $0.value) } ), composeState: composeStates)
    }
}
