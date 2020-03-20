//
// Copyright (c) 12.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ComposeContentViewProtocol: UIView {
    var onSendActionTapped: ComposeMessageViewProtocol.OnUIComposeSendActionTapped? { get set }
    var onStateUpdateTapped: ComposeMessageViewProtocol.OnUIComposeUpdateActionTapped? { get set }
    var messageDictionary: [AnyHashable : Any] { get }
    var intrinsicHeight: CGFloat { get }
    var intrinsicWidth: CGFloat { get }
    
    func clear()
    func removeSendTapAction()
    func populate(message: ComposeContent, siteConfiguration: SiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Bool]?, enableSendButton: Bool, isSelected: Bool)
}

final class ComposeContentView: UIView, ComposeContentViewProtocol {
    private var message: ComposeContent?
    private var selectedOptions: [ComposeContentOption] = []
    
    private var titleLabel: UILabel?
    private var sendButton: UIButton?
    private var optionsButton: [UIButton] = []
    private var composeState: [Bool] = []
    
    // MARK: - UIView life-cycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard self.titleLabel != nil, self.sendButton != nil else { return }
        if self.message?.element == .select {
            self.titleLabel!.frame = CGRect(x: 0, y: 0, width: self.titleLabel!.intrinsicContentSize.width, height: self.titleLabel!.intrinsicContentSize.height)
            
            let y = self.optionsButton.reduce(into: self.titleLabel!.intrinsicContentSize.height + Margins.kComposeVerticalMargin.rawValue) { (y: inout CGFloat, button: UIButton) in
                button.frame = CGRect(x: 0, y: y, width: self.bounds.width, height: Margins.kButtonHeight.rawValue)
                y += Margins.kButtonHeight.rawValue + Margins.kComposeVerticalMargin.rawValue
            }
            
            self.sendButton!.frame = CGRect(x: self.bounds.width - self.sendButton!.intrinsicContentSize.width - Margins.kComposeHorizontalMargin.rawValue, y: y, width: self.sendButton!.intrinsicContentSize.width + Margins.kComposeHorizontalMargin.rawValue, height: Margins.kButtonHeight.rawValue)
        } else if message?.element == .button {
            self.sendButton?.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: Margins.kButtonHeight.rawValue)
        }
    }
    
    private func applyStyle(to button: UIButton?, borderWidth: CGFloat? = nil, selected: Bool) {
        let mainColor: UIColor = (button == self.sendButton) ? .blueButton : .grayButton
        button?.round(radius: Margins.kButtonHeight.rawValue / 2, borderWidth: borderWidth ?? ((selected) ? 0.0 : 2.0), borderColor: mainColor)
        button?.setBackgroundImage((selected) ? UIColor.blueButton.toImage : UIColor.white.toImage, for: .normal)
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
            self.applyStyle(to: sender, selected: true)
            self.onSendActionTapped?(self)
        } else {
            guard let button = self.optionsButton.first(where: { $0 == sender }), let index = self.optionsButton.firstIndex(of: button) else { return }
            let selected = self.selectedOptions[index].selected ?? false
    
            self.applyStyle(to: sender, selected: !selected)
            self.selectedOptions[index].selected = !selected
            self.composeState[index] = !selected
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
        self.message?.content(overrideOptions: self.selectedOptions).toDictionary ?? [:]
    }
    var intrinsicHeight: CGFloat {
        if self.message?.element == .select {
            return (self.titleLabel?.intrinsicContentSize.height ?? 0.0) + CGFloat((self.optionsButton.count + 1)) * (Margins.kButtonHeight.rawValue + Margins.kComposeVerticalMargin.rawValue)
        } else if self.message?.element == .button {
            return Margins.kButtonHeight.rawValue
        }
        return 0
    }
    var intrinsicWidth: CGFloat {
        if self.message?.element == .select {
            return (self.optionsButton.map({ $0.intrinsicContentSize.width }).sorted(by: { $0 > $1 }).first ?? 0) + Margins.kComposeHorizontalMargin.rawValue
        } else if self.message?.element == .button {
            return max(self.sendButton!.intrinsicContentSize.width, self.bounds.width / 2)
        } 
        return 0
    }
    
    func clear() {
        self.selectedOptions = []
        self.optionsButton.forEach { $0.removeFromSuperview() }
        
        self.message = nil
        self.titleLabel = nil
        self.sendButton = nil
    }
    
    func populate(message: ComposeContent, siteConfiguration: SiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Bool]?, enableSendButton: Bool, isSelected: Bool) {
        self.message = message
        
        self.drawTitleAndSend(colorAssets, enableSendButton)
        if message.element == .button {
            self.drawButton(isSelected)
        } else if message.element == .select {
            self.drawSelect(siteConfiguration, composeStates, isSelected)
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
    
    private func drawButton(_ isSelected: Bool) {
        self.titleLabel?.isHidden = true
        self.sendButton?.setTitle(self.message?.label, for: .normal)
        self.applyStyle(to: sendButton, borderWidth: 1.0, selected: isSelected)
        self.updateTitleScale(for: self.sendButton)
        self.composeState = []
    }
    
    private func drawSelect(_ siteConfiguration: SiteConfiguration, _ composeStates: [Bool]?, _ isSelected: Bool) {
        self.titleLabel?.isHidden = false
        self.titleLabel?.text = message?.label
        self.sendButton?.setTitle(siteConfiguration.sendButtonTitle ?? "Send", for: .normal)
        self.applyStyle(to: sendButton, borderWidth: 2.0, selected: isSelected)
    
        /// Clear existing option buttons
        self.optionsButton.forEach { $0.removeFromSuperview() }
        self.composeState = composeStates ?? Array(repeating: false, count: message?.options?.count ?? 0)
    
        /// Recreate options dict to add the "selected" fields
        guard let options = self.message?.options else { return }
        self.selectedOptions = zip(options, self.composeState).map { (arg: (ComposeContentOption, Bool?)) in
            var (option, state) = arg
            option.selected = state
        
            return option
        }
    
        self.optionsButton = zip(options, self.composeState).map { [unowned self] (arg: (ComposeContentOption, Bool?)) in
            let (option, state) = arg
        
            let button = UIButton(type: .custom)
            button.titleLabel?.font = .ninchat
            button.setTitle(option.label, for: .normal)
            button.addTarget(self, action: #selector(self.onButtonTapped(_:)), for: .touchUpInside)
            self.applyStyle(to: button, selected: state ?? false)
            self.updateTitleScale(for: button)
            self.addSubview(button)
        
            return button
        }
    }
}
