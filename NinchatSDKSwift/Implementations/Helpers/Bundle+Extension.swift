//
//  Bundle+Extension.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 5.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import Foundation

extension Bundle {
    static var SDKBundle: Bundle? {
        let classBundle = Bundle(for: NINChatSessionSwift.self)
        guard let bundleURL = classBundle.url(forResource: "NinchatSwiftSDKUI", withExtension: "bundle") else {
            return classBundle
        }
        return Bundle(url: bundleURL)
    }
}
