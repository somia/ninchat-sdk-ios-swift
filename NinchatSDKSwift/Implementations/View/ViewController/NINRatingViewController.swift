//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AutoLayoutSwift

final class NINRatingViewController: UIViewController, ViewController, HasTitleBar, HasDefaultAvatar {
    
    // MARK: - Injected
    
    var viewModel: NINRatingViewModel!
    var style: QuestionnaireStyle? = .form
    
    // MARK: - ViewController

    weak var delegate: NINChatSessionInternalDelegate?
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
    @IBOutlet private(set) weak var infoTextView: UITextView! {
        didSet {
            guard let infoText = self.sessionManager?.siteConfiguration.ratingInfoText else {
                infoTextView.isHidden = true; return
            }
            
            infoTextView.delegate = self
            infoTextView.textAlignment = .center
            infoTextView.setAttributed(text: infoText, font: .ninchat)
        }
    }
    
    // MARK: - Conversation Style Outlets
    
    @IBOutlet private(set) weak var userAvatar: UIImageView!
    @IBOutlet private(set) weak var userAvatarContainerView: UIView!
    @IBOutlet private(set) weak var userTitle: UILabel! {
        didSet {
            userTitle.font = .ninchat
        }
    }
    @IBOutlet private(set) weak var userTitleContainerView: UIView!
    @IBOutlet private(set) weak var titleConversationBubble: UIImageView!
    @IBOutlet private(set) weak var titleConversationTextView: UITextView!
    @IBOutlet private(set) weak var facesConversationViewContainer: UIView!
    
    // MARK: - Form Style Outlets
    
    @IBOutlet private(set) weak var titleFormTextView: UITextView!
    @IBOutlet private(set) weak var facesFormViewContainer: UIView!

    /// MARK: - HasTitleBar

    @IBOutlet private(set) weak var titlebar: UIView?
    @IBOutlet private(set) weak var titlebarContainer: UIView?
    var titlebarAvatar: String? {
        /// - agentAvatar:true, show user_attrs.iconurl everywhere
        /// - agentAvatar:url, show that instead
        
        if let avatar = self.sessionManager?.siteConfiguration.agentAvatar as? Bool, avatar {
            return self.sessionManager?.agent?.iconURL
        }
        return self.sessionManager?.siteConfiguration.agentAvatar as? String
    }
    var titlebarName: String? {
        self.sessionManager?.siteConfiguration.agentName ?? self.sessionManager?.agent?.displayName
    }
    var titlebarJob: String? {
        self.sessionManager?.agent?.info?.job
    }

    // MARK: - HasDefaultAvatar

    var defaultAvatar: UIImage? {
        if let avatar = self.delegate?.override(imageAsset: .ninchatAvatarTitlebar) {
            return avatar
        }
        return UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitleBar(parent: self.topViewContainer, adjustToSafeArea: true) { [weak self] in
            DispatchQueue.main.async {
                self?.onSkipButtonTapped(sender: nil)
            }
        }
        self.overrideAssets()
        
        /// Show conversation-style rating view
        /// according to `https://github.com/somia/mobile/issues/314`
        if style == .conversation {
            self.formStyleView.isHidden = true
            self.conversationStyleView.isHidden = false
            self.facesFormViewContainer.isHidden = true
            self.facesConversationViewContainer.isHidden = false
            self.adjustFaceView(parent: facesConversationViewContainer)
        } else if style == .form {
            self.formStyleView.isHidden = false
            self.conversationStyleView.isHidden = true
            self.facesFormViewContainer.isHidden = false
            self.facesConversationViewContainer.isHidden = true
            self.adjustFaceView(parent: facesFormViewContainer)
        }
        
        self.navigationItem.setHidesBackButton(true, animated: false)
    }

    // MARK: - Setup View
    
    func overrideAssets() {
        facesView.overrideAssets()
        overrideTitlebarAssets()

        if style == .conversation {
            topViewContainer.backgroundColor = .clear
            userTitle.text = self.sessionManager?.siteConfiguration.audienceQuestionnaireUserName ?? ""

            /// remove avatar if titlebar is shown
            let defaultImage = UIImage(named: "icon_avatar_other", in: .SDKBundle, compatibleWith: nil)!
            userAvatar.isHidden = !(self.sessionManager?.siteConfiguration.hideTitlebar ?? true)
            userAvatarContainerView.width?.constant = (userAvatar.isHidden) ? 0 : 35
            userAvatar.leading?.constant = (userAvatar.isHidden) ? 0 : 8
            userTitleContainerView.leading?.constant = (userAvatar.isHidden) ? 16 : 58
            
            if let avatar = self.sessionManager?.siteConfiguration.audienceQuestionnaireAvatar as? String, !avatar.isEmpty {
                userAvatar.image(from: avatar, defaultImage: defaultImage)
            } else {
                userAvatar.image = defaultImage
            }
        }

        if let layer = delegate?.override(layerAsset: .ninchatBackgroundTop) {
            self.topViewContainer.layer.apply(layer)
        }
        if let layer = delegate?.override(layerAsset: .ninchatBackgroundBottom) {
            self.view.layer.apply(layer)
        }
        if let bubbleColor = self.delegate?.override(colorAsset: .ninchatColorChatBubbleLeftTint) {
            self.titleConversationBubble.tintColor = bubbleColor
        }
        if let textTopColor = self.delegate?.override(colorAsset: .ninchatColorTextTop) {
            self.titleFormTextView.textColor = textTopColor
            titleConversationTextView.textColor = textTopColor
        }
        if let textBottomColor = delegate?.override(colorAsset: .ninchatColorTextBottom) {
            self.infoTextView.textColor = textBottomColor
        }
        if let linkColor = self.delegate?.override(colorAsset: .ninchatColorLink) {
            let attribute = [NSAttributedString.Key.foregroundColor: linkColor]
            self.titleFormTextView.linkTextAttributes = attribute
            self.titleConversationTextView.linkTextAttributes = attribute
            self.infoTextView.linkTextAttributes = attribute
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
        
    @IBAction private func onSkipButtonTapped(sender: UIButton?) {
        if self.onRatingFinished(nil) {
            viewModel.skipRating()
        }
    }
}
