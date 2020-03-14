//
// Copyright (c) 12.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

protocol ComposeContentViewProtocol: UIView {
    var onSendActionTapped: ComposeMessageViewProtocol.OnUIComposeSendActionTapped? { get set }
    var onStateUpdateTapped: ComposeMessageViewProtocol.OnUIComposeUpdateActionTapped? { get set }
    var messageDictionary: [AnyHashable : Any] { get }
    var intrinsicHeight: CGFloat { get }
    var intrinsicWidth: CGFloat { get }
    
    func clear()
    func removeSendTapAction()
    func populate(message: NINUIComposeContent, siteConfiguration: SiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Any]?, enableSendButton: Bool, isSelected: Bool)
}

final class ComposeContentView: UIView, ComposeContentViewProtocol {
    
    private var options: Array<[AnyHashable : Any]> = []
    private var composeState: [Any] = []
    
    private var originalContent: NINUIComposeContent?
    private var titleLabel: UILabel?
    private var sendButton: UIButton?
    private var optionsButton: [UIButton] = []
    
    // MARK: - UIView life-cycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard self.titleLabel != nil, self.sendButton != nil else { return }
        if self.originalContent?.element == UIComposeMessageElements.select.rawValue {
            self.titleLabel!.frame = CGRect(x: 0, y: 0, width: self.titleLabel!.intrinsicContentSize.width, height: self.titleLabel!.intrinsicContentSize.height)
            
            let y = self.optionsButton.reduce(into: self.titleLabel!.intrinsicContentSize.height + Margins.kComposeVerticalMargin.rawValue) { (y: inout CGFloat, button: UIButton) in
                button.frame = CGRect(x: 0, y: y, width: self.bounds.width, height: Margins.kButtonHeight.rawValue)
                y += Margins.kButtonHeight.rawValue + Margins.kComposeVerticalMargin.rawValue
            }
            
            self.sendButton!.frame = CGRect(x: self.bounds.width - self.sendButton!.intrinsicContentSize.width - Margins.kComposeHorizontalMargin.rawValue, y: y, width: self.sendButton!.intrinsicContentSize.width + Margins.kComposeHorizontalMargin.rawValue, height: Margins.kButtonHeight.rawValue)
        } else if originalContent?.element == UIComposeMessageElements.button.rawValue {
            self.sendButton?.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: Margins.kButtonHeight.rawValue)
        }
    }
    
    private func applyStyle(to button: UIButton?, borderWidth: CGFloat? = nil, selected: Bool) {
        let mainColor: UIColor = (button == self.sendButton) ? .blueButton : .grayButton
        button?.round(radius: Margins.kButtonHeight.rawValue / 2, borderWidth: borderWidth ?? ((selected) ? 0.0 : 2.0), borderColor: mainColor)
        button?.setBackgroundImage((selected) ? imageFrom(.blueButton) : imageFrom(.white), for: .normal)
        button?.setTitleColor((selected) ? .white : mainColor, for: .normal)
    }
    
    /// `https://github.com/somia/ninchat-sdk-ios/issues/84`
    private func updateTitleScale(for button: UIButton?) {
        button?.titleLabel?.minimumScaleFactor = 0.7
        button?.titleLabel?.adjustsFontSizeToFitWidth = true
        button?.titleLabel?.lineBreakMode = .byTruncatingTail
        button?.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 2, right: 8)
    }
    
    // MARK: - User actions
    
    @objc
    private func onButtonTapped(_ sender: UIButton) {
        if sender == self.sendButton {
            self.onSendActionTapped?(self)
            self.applyStyle(to: sender, selected: true)
        } else {
            guard let button = self.optionsButton.first(where: { $0 == sender }), let index = self.optionsButton.firstIndex(of: button) else { return }
            let selected = (self.options[index]["selected"] as? Bool) ?? false
            
            self.options[index]["selected"] = !selected
            self.composeState[index] = !selected
            self.applyStyle(to: sender, selected: !selected)
            self.onStateUpdateTapped?(self.composeState)
        }
    }
    
    func removeSendTapAction() {
        self.optionsButton.forEach { $0.removeTarget(self, action: #selector(self.onButtonTapped(_:)), for: .touchUpInside) }
        self.sendButton?.removeTarget(self, action: #selector(self.onButtonTapped(_:)), for: .touchUpInside)
    }
    
    // MARK: - ComposeContentViewProtocol
    
    var onSendActionTapped: ComposeMessageViewProtocol.OnUIComposeSendActionTapped?
    var onStateUpdateTapped: ComposeMessageViewProtocol.OnUIComposeUpdateActionTapped?
    var messageDictionary: [AnyHashable : Any] {
        self.originalContent?.dict(withOptions: self.options) ?? [:]
    }
    var intrinsicHeight: CGFloat {
        if originalContent?.element == UIComposeMessageElements.select.rawValue {
            return (self.titleLabel?.intrinsicContentSize.height ?? 0.0) + CGFloat((self.optionsButton.count + 1)) * (Margins.kButtonHeight.rawValue + Margins.kComposeVerticalMargin.rawValue)
        } else if originalContent?.element == UIComposeMessageElements.button.rawValue {
            return Margins.kButtonHeight.rawValue
        }
        return 0
    }
    var intrinsicWidth: CGFloat {
        if originalContent?.element == UIComposeMessageElements.select.rawValue {
            return (self.optionsButton.map({ $0.intrinsicContentSize.width }).sorted(by: { $0 > $1 }).first ?? 0) + Margins.kComposeHorizontalMargin.rawValue
        } else if originalContent?.element == UIComposeMessageElements.button.rawValue {
            return max(self.sendButton!.intrinsicContentSize.width, self.bounds.width / 2)
        } 
        return 0
    }
    
    func clear() {
        self.options = []
        self.optionsButton.forEach { $0.removeFromSuperview() }
        
        self.originalContent = nil
        self.titleLabel = nil
        self.sendButton = nil
    }
    
    func populate(message: NINUIComposeContent, siteConfiguration: SiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Any]?, enableSendButton: Bool, isSelected: Bool) {
        self.originalContent = message
        
        self.drawTitleAndSend(colorAssets, enableSendButton)
        if message.element == UIComposeMessageElements.button.rawValue {
            self.drawButton(message, isSelected)
        } else if message.element == UIComposeMessageElements.select.rawValue {
            self.drawSelect(message, siteConfiguration, composeStates, isSelected)
        }
    }
    
    private func drawTitleAndSend(_ colorAssets: NINColorAssetDictionary, _ enableSendButton: Bool) {
        guard self.titleLabel == nil else { return }
        
        /// Title label
        self.titleLabel = UILabel(frame: .zero)
        self.titleLabel?.font = .ninchat
        self.titleLabel?.textColor = colorAssets[.chatBubbleLeftText] ?? .black
        self.addSubview(self.titleLabel!)
    
        /// Send button
        self.sendButton = UIButton(type: .custom)
        self.sendButton?.titleLabel?.font = .ninchat
        if enableSendButton {
            self.sendButton?.addTarget(self, action: #selector(self.onButtonTapped(_:)), for: .touchUpInside)
        }
        self.addSubview(self.sendButton!)
    
    }
    
    private func drawButton(_ message: NINUIComposeContent, _ isSelected: Bool) {
        self.titleLabel?.isHidden = true
        self.sendButton?.setTitle(message.label, for: .normal)
        self.applyStyle(to: sendButton, borderWidth: 1.0, selected: isSelected)
        self.updateTitleScale(for: self.sendButton)
        self.composeState = []
    }
    
    private func drawSelect(_ message: NINUIComposeContent, _ siteConfiguration: SiteConfiguration, _ composeStates: [Any]?, _ isSelected: Bool) {
        self.titleLabel?.isHidden = false
        self.titleLabel?.text = message.label
        self.sendButton?.setTitle(siteConfiguration.sendButtonTitle ?? "Send", for: .normal)
        self.applyStyle(to: sendButton, borderWidth: 2.0, selected: isSelected)
    
        /// Clear existing option buttons
        self.optionsButton.forEach { $0.removeFromSuperview() }
        self.composeState = composeStates ?? Array(repeating: 0, count: message.options.count)
    
        /// Recreate options dict to add the "selected" fields
        self.options = zip(message.options, self.composeState).map { (arg: ([AnyHashable:Any], Any?)) in
            var (option, state) = arg
            option["selected"] = (state as? Bool) ?? false
        
            return option
        }
    
        self.optionsButton = zip(message.options, self.composeState).map { [unowned self] (arg: ([AnyHashable:Any], Any?)) in
            let (option, state) = arg
        
            let button = UIButton(type: .custom)
            button.titleLabel?.font = .ninchat
            button.setTitle(option["label"] as? String, for: .normal)
            button.addTarget(self, action: #selector(self.onButtonTapped(_:)), for: .touchUpInside)
            self.applyStyle(to: button, selected: (state as? Bool) ?? false)
            self.updateTitleScale(for: button)
            self.addSubview(button)
        
            return button
        }
    }
}