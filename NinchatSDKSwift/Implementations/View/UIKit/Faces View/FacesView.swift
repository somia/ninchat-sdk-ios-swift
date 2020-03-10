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
    var session: NINChatSessionSwift! { get set }
    
    func overrideAssets()
}

final class FacesView: UIView, FacesViewProtocol {
    
    // MARK: - FacesViewProtocol
    
    var session: NINChatSessionSwift!
    var translate: NINChatSessionTranslation!
    
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
        if let positiveTitle = self.translate.translate(key: Constants.kRatingPositiveText.rawValue, formatParams: [:]) {
            self.positiveLabel.text = positiveTitle
        }
        if let positive = self.session.override(imageAsset: .iconRatingPositive) {
            self.positiveButton.setImage(positive, for: .normal)
        }
        if let positiveColor = self.session.override(colorAsset: .ratingPositiveText) {
            self.positiveLabel.textColor = positiveColor
        }
        
        if let neutralTitle = self.translate.translate(key: Constants.kRatingNeutralText.rawValue, formatParams: [:]) {
            self.neutralLabel.text = neutralTitle
        }
        if let neutral = self.session.override(imageAsset: .iconRatingNeutral) {
            self.neutralButton.setImage(neutral, for: .normal)
        }
        if let neutralColor = self.session.override(colorAsset: .ratingNeutralText) {
            self.neutralLabel.textColor = neutralColor
        }
        
        if let negativeTitle = self.translate.translate(key: Constants.kRatingNegativeText.rawValue, formatParams: [:]) {
            self.negativeLabel.text = negativeTitle
        }
        if let negative = self.session.override(imageAsset: .iconRatingNegative) {
            self.negativeButton.setImage(negative, for: .normal)
        }
        if let negativeColor = self.session.override(colorAsset: .ratingNegativeText) {
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
