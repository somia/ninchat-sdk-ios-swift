//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatSDK

final class NINFullScreenViewController: UIViewController, ViewController {
    
    // MARK: - Injected
    
    var viewModel: NINFullScreenViewModel!
    var image: UIImage!
    var attachment: NINFileInfo!
    var onCloseTapped: (() -> Void)?
    
    // MARK: - ViewController
    
    var session: NINChatSessionSwift!
    
    // MARK: - Outlets
    
    private lazy var topBar: TopBarProtocol = {
        var view: TopBar = TopBar.loadFromNib()
        view.session = session
        view.fileName = attachment.name
        view.onCloseTapped = onCloseTapped
        view.onDownloadTapped = { [unowned self] in
            self.viewModel.download(image: self.image, completion: { error in
                if error != nil {
                    NINToast.showWithErrorMessage("Failed to save image", callback: nil)
                } else {
                    NINToast.show(withInfoMessage: "Image saved to Photos", callback: nil)
                }
            })
        }
        
        return view
    }()
    @IBOutlet private(set) weak var imageView: UIImageView! {
        didSet {
            imageView.image = image
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onFullScreenImageTapped(sender:))))
        }
    }
    @IBOutlet private(set) weak var scrollView: UIScrollView!
    
    // MARK: - UIViewController
    
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRation()
        self.topBar.overrideAssets()
    
        self.view.addSubview(topBar)
        topBar
            .fix(top: (0, self.view))
            .fix(leading: (0, self.view), trailing: (0, self.view))
            .fix(height: 60)
    }
}

// MARK: - Setup View

extension NINFullScreenViewController {
    private func setupRation() {
        /// Figure out the max zoom ratio required by comparing the image size to the screen size
        guard let windowSize = UIApplication.shared.keyWindow?.bounds.size else {
            fatalError("No key window")
        }
        let windowDimension = max(windowSize.width, windowSize.height)
        let imageDimension = max(image.size.width, image.size.height)
        self.scrollView.maximumZoomScale = max(1.0, ((imageDimension / windowDimension))) * 1.5
    }
}

// MARK: - User actions

extension NINFullScreenViewController {
    @objc
    private func onFullScreenImageTapped(sender: UITapGestureRecognizer) {
        /// Toggle the top bar visibility
        let isHidden = self.topBar.alpha == 0.0
        UIView.animate(withDuration: 0.3) {
            self.topBar.alpha = (isHidden) ? 1.0 : 0.0
        }
    }
}

// MARK: - UIScrollViewDelegate

extension NINFullScreenViewController {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        self.imageView
    }
}
