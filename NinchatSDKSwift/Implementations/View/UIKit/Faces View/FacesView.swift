//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol FacesViewActions {
    var onPositiveTapped: ((UIButton) -> Void)? { get set }
    var onNeutralTapped: ((UIButton) -> Void)? { get set }
    var onNegativeTapped: ((UIButton) -> Void)? { get set }
}

protocol FacesViewProtocol: UIView, FacesViewActions {
    var delegate: InternalDelegate? { get set }
    var sessionManager: NINChatSessionManager? { get set }

    func overrideAssets()
}

final class FacesView: UIView, FacesViewProtocol {
    
    // MARK: - FacesViewProtocol

    var delegate: InternalDelegate?
    weak var sessionManager: NINChatSessionManager?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var positiveButton: UIButton!
    @IBOutlet private(set) weak var positiveLabel: UILabel!
    @IBOutlet private(set) weak var neutralButton: UIButton!
    @IBOutlet private(set) weak var neutralLabel: UILabel!
    @IBOutlet private(set) weak var negativeButton: UIButton!
    @IBOutlet private(set) weak var negativeLabel: UILabel!
    
    // MARK: - FacesViewActions
    
    var onPositiveTapped: ((UIButton) -> Void)?
    var onNeutralTapped: ((UIButton) -> Void)?
    var onNegativeTapped: ((UIButton) -> Void)?
    
    func overrideAssets() {
        if let positiveTitle = self.sessionManager?.translate(key: Constants.kRatingPositiveText.rawValue, formatParams: [:]) {
            self.positiveLabel.text = positiveTitle
        }
        if let positive = self.delegate?.override(imageAsset: .ninchatIconRatingPositive) {
            self.positiveButton.setImage(positive, for: .normal)
        }
        if let positiveColor = self.delegate?.override(colorAsset: .ninchatColorRatingPositiveText) {
            self.positiveLabel.textColor = positiveColor
        }
        
        if let neutralTitle = self.sessionManager?.translate(key: Constants.kRatingNeutralText.rawValue, formatParams: [:]) {
            self.neutralLabel.text = neutralTitle
        }
        if let neutral = self.delegate?.override(imageAsset: .ninchatIconRatingNeutral) {
            self.neutralButton.setImage(neutral, for: .normal)
        }
        if let neutralColor = self.delegate?.override(colorAsset: .ninchatColorRatingNeutralText) {
            self.neutralLabel.textColor = neutralColor
        }

        if let negativeTitle = self.sessionManager?.translate(key: Constants.kRatingNegativeText.rawValue, formatParams: [:]) {
            self.negativeLabel.text = negativeTitle
        }
        if let negative = self.delegate?.override(imageAsset: .ninchatIconRatingNegative) {
            self.negativeButton.setImage(negative, for: .normal)
        }
        if let negativeColor = self.delegate?.override(colorAsset: .ninchatColorRatingNegativeText) {
            self.negativeLabel.textColor = negativeColor
        }
    }
    
    // MARK: - User actions
    
    @IBAction internal func onPositiveButtonTapped(sender: UIButton) {
        self.onPositiveTapped?(sender)
    }
    
    @IBAction internal func onNeutralButtonTapped(sender: UIButton) {
        self.onNeutralTapped?(sender)
    }
    
    @IBAction internal func onNegativeButtonTapped(sender: UIButton) {
        self.onNegativeTapped?(sender)
    }
}
