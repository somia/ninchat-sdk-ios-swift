//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

final class ChatMetaCell: UITableViewCell, ChatMeta {

    // MARK: - Outlets
    
    @IBOutlet private weak var metaTextLabel: UILabel!
    @IBOutlet private weak var closeChatButtonContainer: UIView!
    @IBOutlet private weak var closeChatButton: NINButton!
    
    // MARK: - ChatMeta
    
    weak var delegate: NINChatSessionInternalDelegate?
    var onCloseChatTapped: ((NINButton) -> Void)?
    
    func populate(message: NINChatMetaMessage, colorAssets: NINColorAssetDictionary) {
        self.applyAssets(message, colorAssets)
        self.metaTextLabel.text = message.text
    }
    
    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        /// Rotate the cell 180 degrees; we will use the table view upside down
        self.rotate()
        
        /// The cell doesnt have any dynamic content; we can freely rasterize it for better scrolling performance
        self.rasterize()
    }
    
    private func applyAssets(_ message: NINChatMetaMessage, _ colorAssets: NINColorAssetDictionary) {
        if let labelColor = colorAssets[.infoText] {
            self.metaTextLabel.textColor = labelColor
        }
        if let title = message.closeChatButtonTitle {
            
            self.deactivate(size: [.height])
            self.closeChatButton.setTitle(title, for: .normal)
            self.closeChatButton.overrideAssets(with: self.delegate, isPrimary: false)
            self.closeChatButton.closure = { [weak self] button in
                self?.onCloseChatTapped?(button)
            }
        } else {
            self.closeChatButtonContainer.fix(height: 0)
            self.closeChatButton.fix(height: 0)
            self.closeChatButton.closure = nil
        }
    }
}
