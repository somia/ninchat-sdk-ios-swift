//
// Copyright (c) 28.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import SwiftUI

final class NINInitialHostController: UIViewController {
    var hostController: UIHostingController<NINInitialView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .initialBottomDefaultBackground
        
        guard let hostController = hostController else {
            fatalError("the controller is not initiated: NinInitialHostController")
        }
        hostController.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        
        addChild(hostController)
        view.addSubview(hostController.view)
        hostController.didMove(toParent: self)
    }
}
