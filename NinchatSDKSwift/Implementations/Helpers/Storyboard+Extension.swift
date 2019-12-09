//
//  Storyboard+Extension.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit

extension UIStoryboard {
    func instantiateViewController<T: UIViewController>() -> T {
        let identifier = String(describing: T.self)
        guard let viewController = self.instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("Failed to load \(identifier) from \(self).storyboard")
        }

        return viewController
    }
}
