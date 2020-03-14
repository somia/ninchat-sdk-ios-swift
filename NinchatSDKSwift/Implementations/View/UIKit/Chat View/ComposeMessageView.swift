//
// Copyright (c) 11.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

protocol ComposeMessageViewProtocol: UIView {
    typealias OnUIComposeSendActionTapped = ((ComposeContentViewProtocol) -> Void)
    var onSendActionTapped: OnUIComposeSendActionTapped? { get set }
    
    typealias OnUIComposeUpdateActionTapped = (([Any]) -> Void)
    var onStateUpdateTapped: OnUIComposeUpdateActionTapped? { get set }
    
    func clear()
    func populate(message: NINUIComposeMessage, siteConfiguration: SiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Any]?)
}

final class ComposeMessageView: UIView, ComposeMessageViewProtocol {
    private var contentViews: [ComposeContentViewProtocol] = []
    private var composeStates: [Any] = []

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
    
    var onSendActionTapped: OnUIComposeSendActionTapped?
    var onStateUpdateTapped: OnUIComposeUpdateActionTapped?
    
    func clear() {
        self.contentViews.forEach { $0.removeFromSuperview() }
        self.invalidateIntrinsicContentSize()
    }

    func populate(message: NINUIComposeMessage, siteConfiguration: SiteConfiguration, colorAssets: NINColorAssetDictionary, composeStates: [Any]?) {
        /// Reusing existing content views that are already allocated results in UI problems for different scenarios, e.g.
        /// `https://github.com/somia/ninchat-sdk-ios/issues/52`
        self.contentViews = []
        self.composeStates = composeStates ?? Array(repeating: 0, count: message.content.count)
        
        let enableSendButton = message.sendPressedIndex() == -1
        message.content.forEach { content in
            let isSelected = content.sendPressed
            let view: ComposeContentViewProtocol = ComposeContentView(frame: .zero)
            view.populate(message: content, siteConfiguration: siteConfiguration, colorAssets: colorAssets, composeStates: composeStates, enableSendButton: enableSendButton, isSelected: isSelected)
            view.isHidden = false
            view.onSendActionTapped = { [unowned self] contentView in
                content.sendPressed = true
    
                /// Make the send buttons un-clickable for this message
                self.contentViews.forEach { $0.removeSendTapAction() }
                self.onSendActionTapped?(contentView)
            }
            view.onStateUpdateTapped = { [unowned self] state in
                self.composeStates[message.content.firstIndex(of: content)!] = state
                self.onStateUpdateTapped?(state)
            }
            
            self.contentViews.append(view)
            self.addSubview(view)
        }
        
        self.invalidateIntrinsicContentSize()
    }
}