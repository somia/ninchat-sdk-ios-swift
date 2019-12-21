//
//  UIButton+Extensions.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 13.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit

extension UIButton {
    @discardableResult
    func roundCorners() -> UIButton {
        self.layer.cornerRadius = self.bounds.height / 2
        return self
    }
}
