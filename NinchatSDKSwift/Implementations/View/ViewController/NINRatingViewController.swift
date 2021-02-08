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
    
    // MARK: - ViewController

    weak var session: NINChatSession?
    weak var sessionManager: NINChatSessionManager?

    var onRatingFinished: ((ChatStatus?) -> Bool)!
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var topViewContainer: UIView!
    @IBOutlet private(set) weak var titleTextView: UITextView!
    
    private lazy var facesView: FacesViewProtocol = {
        var view: FacesView = FacesView.loadFromNib()
        view.session = self.session
        view.sessionManager = self.sessionManager
        view.backgroundColor = .clear
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
    @IBOutlet private(set) weak var facesViewContainer: UIView! {
        didSet {
            facesViewContainer.addSubview(facesView)
            facesView
                .fix(leading: (0, facesViewContainer), trailing: (0, facesViewContainer))
                .fix(top: (0, facesViewContainer), bottom: (0, facesViewContainer))
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
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    // MARK: - Setup View
    
    func overrideAssets() {
        facesView.overrideAssets()
        
        if let title = self.sessionManager?.translate(key: Constants.kRatingTitleText.rawValue, formatParams: [:]) {
            self.titleTextView.setAttributed(text: title, font: .ninchat)
        }
        
        if let skip = self.sessionManager?.translate(key: Constants.kRatingSkipText.rawValue, formatParams: [:]) {
            self.skipButton.setTitle(skip, for: .normal)
        }
        
        if let topBackgroundColor = self.session?.internalDelegate?.override(colorAsset: .backgroundTop) {
            self.topViewContainer.backgroundColor = topBackgroundColor
        }
        
        if let bottomBackgroundColor = self.session?.internalDelegate?.override(colorAsset: .backgroundBottom) {
            self.view.backgroundColor = bottomBackgroundColor
        }
        if let textTopColor = self.session?.internalDelegate?.override(colorAsset: .textTop) {
            self.titleTextView.textColor = textTopColor
        }
        
        if let linkColor = self.session?.internalDelegate?.override(colorAsset: .link) {
            self.titleTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
            self.skipButton.setTitleColor(linkColor, for: .normal)
        }
    }
}

// MARK: - User actions

extension NINRatingViewController {
    private func onPositiveButtonTapped(sender: UIButton) {
        if self.onRatingFinished(.happy) {
            viewModel.rateChat(with: .happy)
        }
    }
    
    private func onNeutralButtonTapped(sender: UIButton) {
        if self.onRatingFinished(.neutral) {
            viewModel.rateChat(with: .neutral)
        }
    }
    
    private func onNegativeButtonTapped(sender: UIButton) {
        if self.onRatingFinished(.sad) {
            viewModel.rateChat(with: .sad)
        }
    }
        
    @IBAction private func onSkipButtonTapped(sender: UIButton) {
        if self.onRatingFinished(nil) {
            viewModel.skipRating()
        }
    }
}
