//
//  NINRatingViewController.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 24.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit

final class NINRatingViewController: UIViewController, ViewController {
    
    // MARK: - Injected
    
    var viewModel: NINRatingViewModel!
    
    // MARK: - ViewController
    
    var session: NINChatSessionSwift!
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var topViewContainer: UIView!
    @IBOutlet private(set) weak var titleTextView: UITextView!
    
    private lazy var facesView: FacesViewProtocol = {
        var view: FacesView = FacesView.loadFromNib()
        view.session = session
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
                .fix(left: (0, facesViewContiner), right: (0, facesViewContiner), isRelative: false)
                .fix(top: (0, facesViewContiner), bottom: (0, facesViewContiner), isRelative: false)
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
