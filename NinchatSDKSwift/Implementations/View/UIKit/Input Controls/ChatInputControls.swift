//
// Copyright (c) 9.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ChatInputActions {
    var onSendTapped: ((String) -> Void)? { get set }
    var onAttachmentTapped: ((UIButton) -> Void)? { get set }
    var onTextSizeChanged: ((CGFloat) -> Void)? { get set }
    var onWritingStatusChanged: ((_ writing: Bool) -> Void)? { get set }

    func updatePermissions(_ permissions: QueuePermissions)
}

protocol ChatInputControlsProtocol: UIView, ChatInputActions {
    var delegate: InternalDelegate? { get set }
    var sessionManager: NINChatSessionManager? { get set }
    var viewModel: NINChatViewModel! { get set }
    var isSelected: Bool! { get set }
    
    func overrideAssets()
}

final class ChatInputControls: UIView, ChatInputControlsProtocol {
    
    private var isOnPlaceholderMode: Bool = true {
        didSet {
            textInput.textColor = (isOnPlaceholderMode) ? placeholderColor : textColor
        }
    }
    private var placeholderColor: UIColor = .systemGray
    private var textColor: UIColor = .black
    private var placeholderText: String {
        self.sessionManager?.translate(key: Constants.kTextInputPlaceholderText.rawValue, formatParams: [:]) ?? ""
    }
    private var isWriting: Bool = false {
        didSet {
            self.onWritingStatusChanged?(isWriting)
        }
    }
    private var timer: Timer?

    // MARK: - ChatInputControls

    var delegate: InternalDelegate?
    weak var sessionManager: NINChatSessionManager?

    var viewModel: NINChatViewModel!
    var isSelected: Bool! = false {
        didSet {
            textInput.becomeFirstResponder()
        }
    }
    
    // MARK: - ChatInputActions
    
    var onSendTapped: ((String) -> Void)?
    var onAttachmentTapped: ((UIButton) -> Void)?
    var onTextSizeChanged: ((CGFloat) -> Void)?
    var onWritingStatusChanged: ((Bool) -> Void)?
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var inputControlsContainerView: UIView!
    @IBOutlet private(set) weak var textInput: UITextView! {
        didSet {
            textInput.delegate = self
            textInput.autocapitalizationType = .sentences
            textInput.autocorrectionType = .yes
        }
    }
    @IBOutlet private(set) weak var attachmentButton: UIButton!
    @IBOutlet private(set) weak var sendMessageButton: UIButton!
    @IBOutlet private(set) weak var sendMessageButtonWidthConstraint: NSLayoutConstraint!
    
    func overrideAssets() {
        if let sendButtonTitle = self.sessionManager?.siteConfiguration.sendButtonTitle {
            self.sendMessageButtonWidthConstraint.isActive = false
            self.sendMessageButton.setImage(nil, for: .normal)
            self.sendMessageButton.backgroundColor = .clear
            self.sendMessageButton.setTitle(sendButtonTitle, for: .normal)
            self.sendMessageButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
            
            if let backgroundColor = self.delegate?.override(colorAsset: .textareaSubmit) {
                self.sendMessageButton.backgroundColor = backgroundColor
                self.sendMessageButton.layer.masksToBounds = true
                self.sendMessageButton.layer.cornerRadius = 16.0
            }
            
            if let backgroundImage = self.delegate?.override(imageAsset: .textareaSubmitButton) {
                self.sendMessageButton.setBackgroundImage(backgroundImage, for: .normal)
            } else if let backgroundBundle = UIImage(named: "icon_send_message_border", in: .SDKBundle, compatibleWith: nil) {
                self.sendMessageButton.setBackgroundImage(backgroundBundle, for: .normal)
            }
            
            if let titleColor = self.delegate?.override(colorAsset: .textareaSubmitText) {
                self.sendMessageButton.setTitleColor(titleColor, for: .normal)
            }
        } else if let buttonImage = self.delegate?.override(imageAsset: .textareaSubmitButton) {
            self.sendMessageButton.setImage(buttonImage, for: .normal)
        }
        
        if let attachmentIcon = self.delegate?.override(imageAsset: .iconTextareaAttachment) {
            self.attachmentButton.setImage(attachmentIcon, for: .normal)
        }
        
        if let inputTextColor = self.delegate?.override(colorAsset: .textareaText) {
            self.textInput.textColor = inputTextColor
            textColor = inputTextColor
        }
        self.updatePlaceholder()
    }

    func updatePermissions(_ permissions: QueuePermissions) {
        /// Hiding buttons results in resizing parent UIStackView
        /// Thus, hide them by making their alpha=0 and isEnabled=false
        attachmentButton.isEnabled = permissions.upload
        attachmentButton.alpha = (permissions.upload) ? 1.0 : 0.0
    }
    
    // MARK: - User actions

    @IBAction internal func onSendButtonTapped(sender: UIButton) {
        let text = textInput.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isOnPlaceholderMode else { return }
        
        textInput.text = ""
        self.onSendTapped?(text)
        self.updatePlaceholder()
        self.isWriting = false
    }
        
    @IBAction internal func onAttachmentButtonTapped(sender: UIButton) {
        self.textInput.resignFirstResponder()
        self.onAttachmentTapped?(sender)
    }

    // MARK: - Helper
    
    private func updatePlaceholder() {
        isOnPlaceholderMode = textInput.text.isEmpty || textInput.text == placeholderText
        if isOnPlaceholderMode {
            textInput.text = placeholderText
        }
        textInput.updateSize(to: textInput.newSize())
        onTextSizeChanged?(textInput.newSize())
    }
}

// MARK: - UITextViewDelegate

extension ChatInputControls: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.text == placeholderText {
            textView.text.removeAll()
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.updatePlaceholder()
        self.isWriting = true

        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        /// send isWriting = false if user stopped typing.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { t in
            t.invalidate()
            self.isWriting = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text == placeholderText {
            textView.text.removeAll()
        }
        return true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.updatePlaceholder()
        self.isWriting = false
        return true
    }
}
