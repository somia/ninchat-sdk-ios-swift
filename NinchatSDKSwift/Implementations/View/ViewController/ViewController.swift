//
//  ViewController.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit
import NinchatSDK

protocol ViewController: UIViewController {
    var session: NINChatSessionSwift! { get set }
}
