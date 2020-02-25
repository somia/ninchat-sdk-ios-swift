//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AutoLayoutSwift

final class NINRatingViewController: UIViewController, ViewController {
    
    // MARK: - Injected
    
    var viewModel: NINRatingViewModel!
    var translate: NINChatSessionTranslation!
    
    // MARK: - ViewController
    
    var session: NINChatSessionSwift!
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var topViewContainer: UIView!
    @IBOutlet private(set) weak var titleTextView: UITextView!
    
    private lazy var facesView: FacesViewProtocol = {
        var view: FacesView = FacesView.loadFromNib()
        view.session = session
        view.translate = translate
        view.onPositiveTapped = { [weak self] button in
            self?.onPositiveButtonTapped(sender: button)
        }
        view.onNeutralTapped = { [weak self] button in
            self?.onNeutralButtonTapped(sender: button)
        }
        view.onNegativeTapped = { [weak self] button in
            self?.onNegativeButtonTapped(sender: button)
        }
        
        return view
    }()
    @IBOutlet private(set) weak var facesViewContiner: UIView! {
        didSet {
            facesViewContiner.addSubview(facesView)
            facesView
                .fix(leading: (0, facesViewContiner), trailing: (0, facesViewContiner))
                .fix(top: (0, facesViewContiner), bottom: (0, facesViewContiner))
        }
    }
    
    @IBOutlet private(set) weak var skipButton: UIButton!
     
    // MARK: - UIViewController
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideAssets()
    }
    
    // MARK: - Setup View
    
    func overrideAssets() {
        facesView.overrideAssets()
        
        if let title = self.translate.translate(key: Constants.kRatingTitleText.rawValue, formatParams: [:]) {
            self.titleTextView.setFormattedText(title)
        }
        
        if let skip = self.translate.translate(key: Constants.kRatingSkipText.rawValue, formatParams: [:]) {
            self.skipButton.setTitle(skip, for: .normal)
        }
        
        if let topBackgroundColor = self.session.override(colorAsset: .backgroundTop) {
            self.topViewContainer.backgroundColor = topBackgroundColor
        }
        
        if let bottomBackgroundColor = self.session.override(colorAsset: .backgroundBottom) {
            self.view.backgroundColor = bottomBackgroundColor
        }
        
        if let textTopColor = self.session.override(colorAsset: .textTop) {
            self.titleTextView.textColor = textTopColor
        }
        
        if let linkColor = self.session.override(colorAsset: .link) {
            self.titleTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
            self.skipButton.setTitleColor(linkColor, for: .normal)
        }
    }
}

// MARK: - User actions

extension NINRatingViewController {
    private func onPositiveButtonTapped(sender: UIButton) {
        viewModel.rateChat(with: .happy)
    }
    
    private func onNeutralButtonTapped(sender: UIButton) {
        viewModel.rateChat(with: .neutral)
    }
    
    private func onNegativeButtonTapped(sender: UIButton) {
        viewModel.rateChat(with: .sad)
    }
        
    @IBAction private func onSkipButtonTapped(sender: UIButton) {
        viewModel.skipRating()
    }
}
