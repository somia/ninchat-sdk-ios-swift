//
//  UITextView+Extensions.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 22.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit

extension UITextView {
    func updateSize(to height: CGFloat) {
        /// Update height constraint value if exists.
        guard let heightConstraint = self.constraints.filter({
            if let item = $0.firstItem as? UITextView {
                return item == self && $0.firstAttribute == .height
            }
            return false
        }).first else {
            fatalError("Height constraint must have been set in IB!")
        }
        heightConstraint.constant = height
        
        self.superview?.setNeedsLayout()
        self.superview?.layoutIfNeeded()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func newSize(maxHeight: CGFloat = 9999) -> CGFloat {
        let newHeight = ceil(self.sizeThatFits(CGSize(width: self.bounds.width, height: 9999)).height)
        return min(newHeight, maxHeight)
    }
}
