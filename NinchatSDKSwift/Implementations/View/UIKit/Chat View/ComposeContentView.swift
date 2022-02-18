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

    var didUpdatedOptions: Bool { get set }
    var message: ComposeContent? { get }
    var sendButton: UIButton? { get }
    var optionsButton: [UIButton] { get }
    var delegate: NINChatSessionInternalDelegate? { get set }

    func clear()
    func removeSendTapAction()
    func onOptionSelected(_ sender: UIButton)
    func populate(message: ComposeContent, siteConfiguration: SiteConfiguration?, colorAssets: NINColorAssetDictionary?, composeStates: [Bool]?, enableSendButton: Bool, isSelected: Bool)
}

final class ComposeContentView: UIView, ComposeContentViewProtocol {
    private(set) var message: ComposeContent?

    private var selectedOptions: [ComposeContentOption] = []
    private var titleLabel: UILabel?
    private(set) var sendButton: UIButton?
    private(set) var optionsButton: [UIButton] = []
    private var composeState: [Bool] = []
    var didUpdatedOptions: Bool = true

    // MARK: - UIView life-cycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let label = self.titleLabel, let send = self.sendButton else { return }
        if self.message?.element == .select {
            label.frame = CGRect(x: 0, y: 0, width: label.intrinsicContentSize.width, height: label.intrinsicContentSize.height)
            let y = self.optionsButton.reduce(into: label.intrinsicContentSize.height + Margins.kComposeVerticalMargin.rawValue) { (y: inout CGFloat, button: UIButton) in
                button.frame = CGRect(x: 0, y: y, width: self.bounds.width, height: Margins.kButtonHeight.rawValue)
                y += Margins.kButtonHeight.rawValue + Margins.kComposeVerticalMargin.rawValue
            }
            send.frame = CGRect(x: self.bounds.width - send.intrinsicContentSize.width - Margins.kComposeHorizontalMargin.rawValue, y: y, width: send.intrinsicContentSize.width + Margins.kComposeHorizontalMargin.rawValue, height: Margins.kButtonHeight.rawValue)
        } else if message?.element == .button {
            self.sendButton?.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: Margins.kButtonHeight.rawValue)
        }
    }
    
    private func applyStyle(to button: UIButton?, borderWidth: CGFloat? = nil, selected: Bool) {
        func applyDefaultStyle(borderColor: UIColor, backgroundImage: UIColor, titleColor: UIColor) {
            button?.round(radius: Margins.kButtonHeight.rawValue/2, borderWidth: borderWidth ?? ((selected) ? 0.0 : 2.0), borderColor: borderColor)
            button?.setBackgroundImage(backgroundImage.toImage, for: .normal)
            button?.setTitleColor(titleColor, for: .normal)
        }
        
        button?.layer.sublayers?.first(where: { $0.name == LAYER_NAME })?.removeFromSuperlayer()
        
        if button == self.sendButton {
            if selected, let layer = self.delegate?.override(layerAsset: .ninchatComposeSubmitSelectedButton) {
                button?.layer.apply(layer)
            } else if let layer = self.delegate?.override(layerAsset: .ninchatComposeSubmitButton) {
                button?.layer.apply(layer)
            } else {
                applyDefaultStyle(borderColor: .blueButton, backgroundImage: (selected) ? .blueButton : .white, titleColor: (selected) ? .white : .blueButton)
            }
        } else {
            if selected, let layer = self.delegate?.override(layerAsset: .ninchatComposeSelectedButton) {
                button?.layer.apply(layer)
            } else if let layer = self.delegate?.override(layerAsset: .ninchatComposeUnselectedButton) {
                button?.layer.apply(layer)
            } else {
                applyDefaultStyle(borderColor: .grayButton, backgroundImage: (selected) ? .blueButton : .white, titleColor: (selected) ? .white : .grayButton)
            }
        }
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    /// `https://github.com/somia/ninchat-sdk-ios/issues/84`
    private func updateTitleScale(for button: UIButton?) {
        button?.updateTitleScale()
        button?.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 2, right: 8)
    }
    
    // MARK: - User actions
    
    @objc
    func onOptionSelected(_ sender: UIButton) {
        if sender == self.sendButton, let closure = self.onSendActionTapped {
            self.applyStyle(to: sender, selected: true)
            closure(self, self.didUpdatedOptions)
        } else if let closure = self.onStateUpdateTapped {
            guard let button = self.optionsButton.first(where: { $0 == sender }), let index = self.optionsButton.firstIndex(of: button) else { return }
            let selected = self.selectedOptions[index].selected ?? false
    
            self.applyStyle(to: sender, selected: !selected)
            self.selectedOptions[index].selected = !selected
            self.composeState[index] = !selected
            closure(self.composeState, true)
        }
    }

    func removeSendTapAction() {
        self.optionsButton.forEach { $0.removeTarget(self, action: #selector(self.onOptionSelected(_:)), for: .touchUpInside) }
        self.sendButton?.removeTarget(self, action: #selector(self.onOptionSelected(_:)), for: .touchUpInside)
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
    var delegate: NINChatSessionInternalDelegate?
    
    func clear() {
        self.selectedOptions = []
        self.optionsButton.forEach { $0.removeFromSuperview() }
        
        self.message = nil
        self.titleLabel = nil
        self.sendButton = nil
    }
    
    func populate(message: ComposeContent, siteConfiguration: SiteConfiguration?, colorAssets: NINColorAssetDictionary?, composeStates: [Bool]?, enableSendButton: Bool, isSelected: Bool) {
        self.message = message
        
        self.drawTitleAndSend(colorAssets, enableSendButton)
        if message.element == .button {
            self.drawButton(isSelected)
        } else if message.element == .select {
            self.drawSelect(siteConfiguration, composeStates, isSelected)
        }
    }
    
    private func drawTitleAndSend(_ colorAssets: NINColorAssetDictionary?, _ enableSendButton: Bool) {
        guard self.titleLabel == nil else { return }
        
        /// Title label
        self.titleLabel = UILabel(frame: .zero)
        self.titleLabel?.font = .ninchat
        self.titleLabel?.textColor = colorAssets?[.ninchatColorChatBubbleLeftText] ?? .black
        self.addSubview(self.titleLabel!)
    
        /// Send button
        self.sendButton = UIButton(type: .custom)
        self.sendButton?.titleLabel?.font = .ninchat
        if enableSendButton {
            self.sendButton?.addTarget(self, action: #selector(self.onOptionSelected(_:)), for: .touchUpInside)
        }
        self.addSubview(self.sendButton!)
    
    }
    
    private func drawButton(_ isSelected: Bool) {
        self.titleLabel?.isHidden = true
        self.sendButton?.setTitle(self.message?.label, for: .normal)
        self.applyStyle(to: sendButton, borderWidth: 1.0, selected: isSelected)
        self.updateTitleScale(for: self.sendButton)
        self.composeState = []
        self.optionsButton.append(self.sendButton!)
    }
    
    private func drawSelect(_ siteConfiguration: SiteConfiguration?, _ composeStates: [Bool]?, _ isSelected: Bool) {
        self.titleLabel?.isHidden = false
        self.titleLabel?.text = message?.label
        self.sendButton?.setTitle(siteConfiguration?.sendButtonTitle ?? "Send", for: .normal)
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
        self.optionsButton = zip(options, self.composeState).map { [weak self] (arg: (ComposeContentOption, Bool?)) in
            let (option, state) = arg
        
            let button = UIButton(type: .custom)
            button.titleLabel?.font = .ninchat
            button.setTitle(option.label, for: .normal)
            button.addTarget(self, action: #selector(self?.onOptionSelected(_:)), for: .touchUpInside)
            self?.applyStyle(to: button, selected: state ?? false)
            self?.updateTitleScale(for: button)
            self?.addSubview(button)

            return button
        }
    }

    deinit {
        /// To ensure that the blocks are deallocated to prevent the following issue to happening again
        /// https://github.com/somia/ninchat-sdk-ios/issues/100
        self.onSendActionTapped = nil
        self.onStateUpdateTapped = nil
    }
}
