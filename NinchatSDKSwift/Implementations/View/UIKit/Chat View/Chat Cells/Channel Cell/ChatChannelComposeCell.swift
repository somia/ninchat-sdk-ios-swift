//
// Copyright (c) 29.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

class ChatChannelComposeCell: ChatChannelOthersCell {
    
    override var onComposeSendTapped: ((ComposeContentViewProtocol, _ didUpdateOptions: Bool) -> Void)? {
        set {
            self.composeMessageView.onSendActionTapped = { compose, didUpdateOptions in
                newValue?(compose, didUpdateOptions)
            }
        }
        get {
            self.composeMessageView.onSendActionTapped
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var composeMessageView: ComposeMessageView!
    
    // MARK: - UITableViewCell life-cycle
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.onComposeSendTapped = nil
        self.composeMessageView.clear()
    }
    
    func populateCompose(message: ComposeMessage, configuration: SiteConfiguration?, colorAssets: NINColorAssetDictionary?, composeStates: [Bool]?) {
        self.composeMessageView.delegate = self.delegate
        self.composeMessageView.clear()
        self.composeMessageView.onStateUpdateTapped = { [weak self] composeStates, didUpdateOptions in
            self?.onComposeUpdateTapped?(composeStates, didUpdateOptions)
        }
        self.composeMessageView.populate(message: message, siteConfiguration: configuration, colorAssets: colorAssets, composeStates: composeStates)
    }
}
