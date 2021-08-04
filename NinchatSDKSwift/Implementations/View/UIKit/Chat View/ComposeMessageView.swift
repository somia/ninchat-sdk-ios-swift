//
// Copyright (c) 11.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ComposeMessageViewProtocol: UIView {
    /*
    * didUpdateOptions: defines if the selection has to be sent to the server, or it is just a UI update
    */
    typealias OnUIComposeSendActionTapped = (ComposeContentViewProtocol, _ didUpdateOptions: Bool) -> Void
    typealias OnUIComposeUpdateActionTapped = ([Bool], _ didUpdateOptions: Bool) -> Void

    var delegate: NINChatSessionInternalDelegate? { get set }
    var onSendActionTapped: OnUIComposeSendActionTapped? { get set }
    var onStateUpdateTapped: OnUIComposeUpdateActionTapped? { get set }
    
    func clear()
    func updateStates(with action: ComposeUIAction)
    func disableUserInteraction(_ disable: Bool)
    func populate(message: ComposeMessage, siteConfiguration: SiteConfiguration?, colorAssets: NINColorAssetDictionary?, composeStates: [Bool]?)
}

final class ComposeMessageView: UIView, ComposeMessageViewProtocol {
    private var contentViews: [ComposeContentViewProtocol] = []
    private var composeStates: [Bool] = []

    private var isActive: Bool {
        self.contentViews.count > 0 && !(self.contentViews.first?.isHidden ?? true)
    }
    private var intrinsicHeight: CGFloat {
        guard self.isActive else { return UIView.noIntrinsicMetric }
        
        return self.contentViews.reduce(into: 0) { (result: inout CGFloat, subview: ComposeContentViewProtocol) in
            result += subview.intrinsicHeight
        } + CGFloat((self.contentViews.count - 1)) * Margins.kComposeVerticalMargin.rawValue
    }
    private var intrinsicWidth: CGFloat {
        guard self.isActive else { return UIView.noIntrinsicMetric }
    
        return self.contentViews.map { $0.intrinsicWidth }.sorted(by: { $0 > $1 }).first ?? 0
    }
    override var intrinsicContentSize: CGSize {
        self.isActive ? CGSize(width: self.intrinsicWidth + 60.0, height: self.intrinsicHeight) : CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    
    // MARK: - UIView life-cycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        _ = self.contentViews.reduce(into: 0) { (y: inout CGFloat, view: ComposeContentViewProtocol) in
            view.frame = CGRect(x: 0, y: y, width: self.bounds.width, height: view.intrinsicHeight)
            y += view.intrinsicHeight + Margins.kComposeVerticalMargin.rawValue
        }
    }
    
    // MARK: - ComposeMessageViewProtocol
    
    var delegate: NINChatSessionInternalDelegate?
    var onSendActionTapped: OnUIComposeSendActionTapped?
    var onStateUpdateTapped: OnUIComposeUpdateActionTapped?
    
    func clear() {
        self.contentViews.forEach { $0.removeFromSuperview() }
        self.invalidateIntrinsicContentSize()
    }

    func updateStates(with action: ComposeUIAction) {
        debugger("Start updating compose states received from the server")

        self.contentViews.forEach { view in
            guard action.target == view.message, view.didUpdatedOptions, let sendButton = view.sendButton else { return }
            view.didUpdatedOptions = false

            action.target.options?.filter({ $0.selected ?? false }).forEach({ option in
                if let optionButton = view.optionsButton.first(where: { $0.titleLabel?.text == option.label }) {
                    view.onOptionSelected(optionButton)
                }
            })
            view.onOptionSelected(sendButton)
        }
    }

    func disableUserInteraction(_ disable: Bool) {
        self.contentViews.forEach({ $0.isUserInteractionEnabled = !disable })
    }

    func populate(message: ComposeMessage, siteConfiguration: SiteConfiguration?, colorAssets: NINColorAssetDictionary?, composeStates: [Bool]?) {
        /// Reusing existing content views that are already allocated results in UI problems for different scenarios, e.g.
        /// `https://github.com/somia/ninchat-sdk-ios/issues/52`
        self.contentViews = []
        self.composeStates = composeStates ?? Array(repeating: false, count: message.content.count)
        
        let enableSendButton = message.sendPressedIndex == -1
        message.content.forEach { [weak self] (content: ComposeContent) in
            let view: ComposeContentViewProtocol = ComposeContentView(frame: .zero)
            view.delegate = self?.delegate
            view.populate(message: content, siteConfiguration: siteConfiguration, colorAssets: colorAssets, composeStates: composeStates, enableSendButton: enableSendButton, isSelected: content.sendPressed ?? false)
            view.isHidden = false
            view.onSendActionTapped = { [weak self] contentView, didUpdateOptions in
                content.sendPressed = true
    
                /// Make the send buttons un-clickable for this message
                self?.contentViews.forEach { $0.removeSendTapAction() }
                self?.onSendActionTapped?(contentView, didUpdateOptions)
            }
            view.onStateUpdateTapped = { [weak self] state, didUpdateOptions in
                self?.composeStates = state
                self?.onStateUpdateTapped?(self?.composeStates ?? [], didUpdateOptions)
            }
            
            self?.contentViews.append(view)
            self?.addSubview(view)
        }
        
        self.invalidateIntrinsicContentSize()
    }
}
