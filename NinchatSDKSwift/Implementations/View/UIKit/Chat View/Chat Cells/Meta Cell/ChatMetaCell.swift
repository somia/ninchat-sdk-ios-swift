//
// Copyright (c) 6.1.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AutoLayoutSwift

final class ChatMetaCell: UITableViewCell, ChatMeta, HasCustomLayer {

    // MARK: - Outlets
    
    @IBOutlet private weak var metaTextLabelContainer: UIView!
    @IBOutlet private weak var metaTextLabel: UILabel! {
        didSet {
            metaTextLabel.font = .ninchat
        }
    }
    @IBOutlet private weak var metaTextIcon: UIImageView! {
        didSet {
            metaTextIcon.contentMode = .scaleAspectFit
        }
    }
    @IBOutlet private weak var closeChatButtonContainer: UIView!
    @IBOutlet private weak var closeChatButton: CloseButton!
    
    // MARK: - ChatMeta
    
    weak var delegate: NINChatSessionInternalDelegate?
    var onCloseChatTapped: ((NINButton) -> Void)?
    
    func populate(message: MetaMessage, colorAssets: NINColorAssetDictionary?) {
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didRotateView(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.applyLayerOverride(view: metaTextLabelContainer)
    }
    
    private func applyAssets(_ message: MetaMessage, _ colorAssets: NINColorAssetDictionary?) {
        if let labelColor = colorAssets?[.ninchatColorInfoText] {
            self.metaTextLabel.textColor = labelColor
        }
        if let title = message.closeChatButtonTitle {
            self.deactivate(constraints: [.height])
            self.closeChatButton.buttonTitle = title
            self.closeChatButton.overrideAssets(with: self.delegate, in: .general)
            self.closeChatButton.closure = { [weak self] button in
                self?.onCloseChatTapped?(button)
            }
        } else {
            self.closeChatButton.deactivate(constraints: [.top, .bottom])
            self.closeChatButtonContainer.fix(height: 0)
            self.closeChatButton.fix(height: 0)
            self.onCloseChatTapped = nil
        }
        
        if let metaLabelContainerLayer = self.delegate?.override(layerAsset: .ninchatMetadataContainer) {
            self.metaTextLabelContainer.layer.insertSublayer(metaLabelContainerLayer, at: 0)
        } else {
            metaTextLabelContainer.round(radius: 15.0)
        }
        
        if let metaIcon = self.delegate?.override(imageAsset: .ninchatIconMetadata) {
            metaTextIcon.image = metaIcon
        } else {
            metaTextIcon.tintColor = .QBlueButtonNormal
        }
    }
    
    @objc
    func didRotateView(_ notification: Notification) {
        self.applyLayerOverride(view: metaTextLabelContainer)
    }
}
