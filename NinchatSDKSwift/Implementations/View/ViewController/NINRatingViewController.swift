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
    var style: QuestionnaireStyle? = .form
    
    // MARK: - ViewController

    var delegate: InternalDelegate?
    weak var sessionManager: NINChatSessionManager?
    var onRatingFinished: ((ChatStatus?) -> Bool)!
    
    private lazy var facesView: FacesViewProtocol = {
        var view: FacesView = FacesView.loadFromNib()
        view.delegate = self.delegate
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
    
    // MARK: - Shared Outlets
    
    @IBOutlet private(set) weak var topViewContainer: UIView!
    @IBOutlet private(set) weak var conversationStyleView: UIView!
    @IBOutlet private(set) weak var formStyleView: UIView!
    @IBOutlet private(set) weak var skipButton: UIButton!

    // MARK: - Conversation Style Outlets
    
    @IBOutlet private(set) weak var userAvatar: UIImageView!
    @IBOutlet private(set) weak var userTitle: UILabel! {
        didSet {
            userTitle.font = .ninchat
        }
    }
    @IBOutlet private(set) weak var titleConversationBubble: UIImageView!
    @IBOutlet private(set) weak var titleConversationTextView: UITextView!
    @IBOutlet private(set) weak var facesConversationViewContainer: UIView!
    
    // MARK: - Form Style Outlets
    
    @IBOutlet private(set) weak var titleFormTextView: UITextView!
    @IBOutlet private(set) weak var facesFormViewContainer: UIView!
     
    // MARK: - UIViewController
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// Show conversation-style rating view
        /// according to `https://github.com/somia/mobile/issues/314`
        conversationStyleView.isHidden = (style != .conversation)
        formStyleView.isHidden = !conversationStyleView.isHidden
        if style == .conversation {
            self.adjustFaceView(parent: facesConversationViewContainer)
        } else if style == .form {
            self.adjustFaceView(parent: facesFormViewContainer)
        }
        
        self.overrideAssets()
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    // MARK: - Setup View
    
    func overrideAssets() {
        facesView.overrideAssets()
        
        if style == .conversation {
            topViewContainer.backgroundColor = .clear
            
            userTitle.text = self.sessionManager?.siteConfiguration.audienceQuestionnaireUserName ?? ""
            if let avatar = self.sessionManager?.siteConfiguration.audienceQuestionnaireAvatar as? String, !avatar.isEmpty {
                userAvatar.image(from: avatar)
            } else {
                userAvatar.image = UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)
            }
            
        }
        
        if let topBackgroundColor = self.delegate?.override(colorAsset: .backgroundTop) {
            self.topViewContainer.backgroundColor = topBackgroundColor
        }
        if let bottomBackgroundColor = self.delegate?.override(colorAsset: .backgroundBottom) {
            self.view.backgroundColor = bottomBackgroundColor
        }
        if let bubbleColor = self.delegate?.override(colorAsset: .ninchatColorChatBubbleLeftTint) {
            self.titleConversationBubble.tintColor = bubbleColor
        }
        if let textTopColor = self.delegate?.override(colorAsset: .ninchatColorTextTop) {
            self.titleFormTextView.textColor = textTopColor
            titleConversationTextView.textColor = textTopColor
        }
        
        if let linkColor = self.delegate?.override(colorAsset: .ninchatColorLink) {
            self.titleFormTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
            titleConversationTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkColor]
            self.skipButton.setTitleColor(linkColor, for: .normal)
        }
        
        if let skip = self.sessionManager?.translate(key: Constants.kRatingSkipText.rawValue, formatParams: [:]) {
            self.skipButton.setTitle(skip, for: .normal)
        }
        if let title = self.sessionManager?.translate(key: Constants.kRatingTitleText.rawValue, formatParams: [:]) {
            self.titleFormTextView.setAttributed(text: title, font: .ninchat)
            titleConversationTextView.setAttributed(text: title, font: .ninchat)
        }
    }
    
    func adjustFaceView(parent: UIView) {
        parent.addSubview(facesView)
        facesView
            .fix(leading: (0, parent), trailing: (0, parent))
            .fix(top: (0, parent), bottom: (0, parent))

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
