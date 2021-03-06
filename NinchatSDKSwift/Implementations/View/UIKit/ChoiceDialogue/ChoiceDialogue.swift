//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

enum ChoiceDialogueResult {
    case select(Int)
    case cancel
}

final class ChoiceDialogue: UIView {
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var stackView: UIStackView!
    
    // MARK: - ChoiceDialogue
    
    private var onCompletion: ((ChoiceDialogueResult) -> Void)?

    class func showDialogue(withOptions options:[String], cancelTitle: String? = nil, onCompletion: @escaping ((ChoiceDialogueResult) -> Void)) {
        let view: ChoiceDialogue = ChoiceDialogue.loadFromNib()
        view.showDialogue(withOptions: options, cancelTitle: cancelTitle, onCompletion: onCompletion)
    }

    internal func showDialogue(withOptions options:[String], cancelTitle: String? = nil, onCompletion: @escaping ((ChoiceDialogueResult) -> Void)) {
        self.onCompletion = onCompletion
        self.transform = CGAffineTransform(translationX: 0, y: bounds.height)

        self.addView(to: UIApplication.shared.keyWindow)
        self.addOptions(options, cancel: cancelTitle ?? "Cancel".localized)
        self.animateDialogue(hide: false)
    }

    private func addView(to window: UIWindow?) {
        guard let parent = window else { return }

        parent.addSubview(self)
        self
            .fix(bottom: (0, parent), toSafeArea: true)
            .fix(leading: (0, parent), trailing: (0, parent))
    }

    private func addOptions(_ options: [String], cancel: String) {
        (options + [cancel]).forEach {
            let row: ChoiceDialogueRow = ChoiceDialogueRow.loadFromNib()
            row.setup(title: $0, tag: options.firstIndex(of: $0) ?? -1, isCancel: $0 == cancel) { [weak self] index, isCanceled in
                DispatchQueue.main.async {
                    if isCanceled {
                        self?.onCancelTapped()
                    } else {
                        self?.animateDialogue(hide: true) { self?.onCompletion?(.select(index)) }
                    }
                }
            }
            
            self.stackView.addArrangedSubview(row)
        }
    }
    
    private func animateDialogue(hide: Bool, completion: (() -> Void)? = nil) {
        self.hide(hide, withActions: { [weak self] in
            self?.transform = (hide) ? CGAffineTransform(translationX: 0, y: (self?.bounds.height ?? 0)) : .identity
        }, andCompletion: {
            completion?()
        })
    }
    
    // MARK: - User actions
    
    private func onCancelTapped() {
        self.animateDialogue(hide: true) {
            self.removeFromSuperview()
            self.onCompletion?(.cancel)
        }
    }
}

final class ChoiceDialogueRow: UIView {
    
    // MARK: - Outlets
    
    @IBOutlet private(set) weak var titleLabel: UILabel!
    
    // MARK: - ChoiceDialogueRow
    
    private var onRowTapped: ((Int, _ isCanceled: Bool) -> Void)?
    
    func setup(title: String, tag: Int, isCancel: Bool, onRowTapped: @escaping ((Int, Bool) -> Void)) {
        self.round(radius: 0.0, borderWidth: 0.5, borderColor: UIColor(white: 0, alpha: 0.4))
        
        self.tag = tag
        self.titleLabel.text = title
        self.titleLabel.textColor = (isCancel) ? .red : .black
        self.onRowTapped = onRowTapped
    }
    
    // MARK: - User actions
    
    @IBAction internal func onRowButtonTapped(_ sender: UIButton?) {
        self.onRowTapped?(self.tag, self.titleLabel.textColor == .red)
    }
}