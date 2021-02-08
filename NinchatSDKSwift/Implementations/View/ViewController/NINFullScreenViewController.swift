//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINFullScreenViewController: UIViewController, ViewController {
    
    // MARK: - Injected
    
    var viewModel: NINFullScreenViewModel!
    var image: UIImage!
    var attachment: FileInfo!
    var onCloseTapped: (() -> Void)?
    
    // MARK: - ViewController
    
    weak var session: NINChatSession?
    weak var sessionManager: NINChatSessionManager?
    
    // MARK: - Outlets
    
    private lazy var topBar: TopBarProtocol = {
        var view: TopBar = TopBar.loadFromNib()
        view.session = session
        view.fileName = attachment.name
        view.onCloseTapped = onCloseTapped
        view.onDownloadTapped = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.viewModel.download(image: weakSelf.image, completion: { error in
                if error != nil {
                    Toast.show(message: .error("Failed to save image"))
                } else {
                    Toast.show(message: .info("Image saved to Photos"))
                }
            })
        }
        
        return view
    }()
    @IBOutlet private(set) weak var imageView: UIImageView! {
        didSet {
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
            .fix(top: (0, self.view), toSafeArea: true)
            .fix(leading: (0, self.view), trailing: (0, self.view))
            .fix(height: 60)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /// Update image
        imageView.image = image
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: true)
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
        UIView.animate(withDuration: TimeConstants.kAnimationDuration.rawValue) {
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
