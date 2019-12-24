//
//  ChatInputControls.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 9.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit
import NinchatSDK

protocol ChatInputActions {
    var onSendTapped: ((String) -> Void)? { get set }
    var onAttachmentTapped: ((UIButton) -> Void)? { get set }
    var onTextSizeChanged: ((CGFloat) -> Void)? { get set }
}

protocol ChatInputControlsProtocol: UIView, ChatInputActions {
    var session: NINChatSessionSwift? { get set }
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
        return self.session?.sessionManager.translation(Constants.kTextInputPlaceholderText.rawValue, formatParams: [:]) ?? ""
    }
    
    // MARK: - ChatInputControls
    
    var session: NINChatSessionSwift?
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
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var inputControlsContainerView: UIView!
    @IBOutlet private(set) weak var textInput: UITextView! {
        didSet {
            textInput.delegate = self
        }
    }
    @IBOutlet private(set) weak var attachmentButton: UIButton!
    @IBOutlet private(set) weak var sendMessageButton: UIButton!
    @IBOutlet private(set) weak var sendMessageButtonWidthConstraint: NSLayoutConstraint!
    
    func overrideAssets() {
        if let sendButtonTitle = self.session?.sessionManager.siteConfiguration.sendButtonTitle {
            self.sendMessageButtonWidthConstraint.isActive = false
            self.sendMessageButton.setImage(nil, for: .normal)
            self.sendMessageButton.setTitle(sendButtonTitle, for: .normal)
            self.sendMessageButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
            
            if let backgroundImage = self.session?.override(imageAsset: .textareaSubmitButton) {
                self.sendMessageButton.setBackgroundImage(backgroundImage, for: .normal)
            } else if let backgroundBundle = UIImage(named: "icon_send_message_border", in: .SDKBundle, compatibleWith: nil) {
                self.sendMessageButton.setBackgroundImage(backgroundBundle, for: .normal)
            }
            
            if let titleColor = self.session?.override(colorAsset: .textareaSubmitText) {
                self.sendMessageButton.setTitleColor(titleColor, for: .normal)
            }
        } else if let buttonImage = self.session?.override(imageAsset: .textareaSubmitButton) {
            self.sendMessageButton.setImage(buttonImage, for: .normal)
        }
        
        if let attachmentIcon = self.session?.override(imageAsset: .iconTextareaAttachment) {
            self.attachmentButton.setImage(attachmentIcon, for: .normal)
        }

        if let inputTextColor = self.session?.overrideColorAsset(forKey: .textareaText) {
            self.textInput.textColor = inputTextColor
            textColor = inputTextColor
        }
        self.updatePlaceholder()
    }
    
    // MARK: - User actions

    @IBAction private func onSendButtonTapped(sender: UIButton) {
        let text = textInput.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isOnPlaceholderMode else { return }
        
        textInput.text = ""
        self.onSendTapped?(text)
        self.updatePlaceholder()
        textInput.resignFirstResponder()
    }
        
    @IBAction private func onAttachmentButtonTapped(sender: UIButton) {
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
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.updatePlaceholder()
        return true
    }
}

// MARK: - Test Facilities

extension ChatInputControls {
    internal func sendAction() {
        self.onSendButtonTapped(sender: sendMessageButton)
    }
    
    internal func attachmentAction() {
        self.onAttachmentButtonTapped(sender: sendMessageButton)
    }
}
