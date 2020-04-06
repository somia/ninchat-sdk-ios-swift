//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AVKit
import CoreServices
import WebRTC

protocol Coordinator: class {
    init(with session: NINChatSessionSwift)
    func start(with queue: String?, resumeSession: Bool, within navigation: UINavigationController) -> UIViewController?
}

final class NINCoordinator: Coordinator {
    
    // MARK: - Coordinator
    
    internal unowned let session: NINChatSessionSwift
    internal weak var navigationController: UINavigationController? {
        didSet {
            if #available(iOS 13.0, *) {
                navigationController?.overrideUserInterfaceStyle = .light
            }
        }
    }
    internal var storyboard: UIStoryboard {
        return UIStoryboard(name: "Chat", bundle: .SDKBundle)
    }
    internal var sessionManager: NINChatSessionManager {
        return session.sessionManager
    }
    
    init(with session: NINChatSessionSwift) {
        self.session = session
    }
    
    func start(with queue: String?, resumeSession: Bool, within navigation: UINavigationController) -> UIViewController? {
        self.navigationController = navigation
        if resumeSession {
            return joinChatViewController()
        } else if let queue = queue {
            return joinAutomatically(for: queue)
        }
        return showJoinOptions()
    }
}

// MARK: - Navigation

extension NINCoordinator {
    internal func joinAutomatically(for queue: String) -> UIViewController? {
        guard let target = self.sessionManager.queues.filter({ $0.queueID == queue }).first else {
            return nil
        }
        return joinDirectly(to: target)
    }
    
    internal func showQueueViewController(for queue: Queue?) {
        guard let target = queue, let queueVC = joinDirectly(to: target) else { return }
        self.navigationController?.pushViewController(queueVC, animated: true)
    }
    
    @discardableResult
    internal func showChatViewController() -> UIViewController {
        let chatViewController = joinChatViewController()
        self.navigationController?.pushViewController(chatViewController, animated: true)

        return chatViewController
    }

    @discardableResult
    internal func showFullScreenViewController(_ image: UIImage, _ attachment: FileInfo) -> UIViewController? {
        let viewModel: NINFullScreenViewModel = NINFullScreenViewModelImpl(delegate: self.session)
        let previewViewController: NINFullScreenViewController = storyboard.instantiateViewController()
        previewViewController.viewModel = viewModel
        previewViewController.session = session
        previewViewController.image = image
        previewViewController.attachment = attachment
        previewViewController.onCloseTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        self.navigationController?.pushViewController(previewViewController, animated: true)
        return previewViewController
    }
    
    @discardableResult
    internal func showRatingViewController() -> UIViewController? {
        let viewModel: NINRatingViewModel = NINRatingViewModelImpl(sessionManager: self.sessionManager)
        let ratingViewController: NINRatingViewController = storyboard.instantiateViewController()
        ratingViewController.session = session
        ratingViewController.viewModel = viewModel
        ratingViewController.translate = sessionManager
        
        self.navigationController?.pushViewController(ratingViewController, animated: true)
        return ratingViewController
    }
}

// MARK: - Initial View Controller

extension NINCoordinator {
    internal func showJoinOptions() -> UIViewController? {
        let initialViewController: NINInitialViewController = storyboard.instantiateViewController()
        initialViewController.session = session
        initialViewController.onQueueActionTapped = { [weak self] queue in
            self?.showQueueViewController(for: queue)
        }
        
        return initialViewController
    }
    
    @discardableResult
    internal func joinDirectly(to queue: Queue) -> UIViewController? {
        let viewModel: NINQueueViewModel = NINQueueViewModelImpl(sessionManager: self.sessionManager, queue: queue, delegate: self.session)
        let joinViewController: NINQueueViewController = storyboard.instantiateViewController()
        joinViewController.session = session
        joinViewController.viewModel = viewModel
        joinViewController.onQueueActionTapped = { [weak self] in
            self?.showChatViewController()
        }
        
        return joinViewController
    }

    @discardableResult
    internal func joinChatViewController() -> UIViewController {
        let viewModel: NINChatViewModel = NINChatViewModelImpl(sessionManager: self.sessionManager)
        let videoDelegate: NINRTCVideoDelegate = NINRTCVideoDelegateImpl()
        let mediaDelegate: NINPickerControllerDelegate = chatMediaPicker(viewModel)
        let chatViewController: NINChatViewController = storyboard.instantiateViewController()
        chatViewController.viewModel = viewModel
        chatViewController.session = session
        chatViewController.chatDataSourceDelegate = chatDataSourceDelegate(viewModel)
        chatViewController.chatVideoDelegate = videoDelegate
        chatViewController.chatRTCDelegate = chatRTCDelegate(videoDelegate)
        chatViewController.chatMediaPickerDelegate = mediaDelegate

        chatViewController.onOpenGallery = { [weak self] source in
            DispatchQueue.main.async {
                let controller = UIImagePickerController()
                controller.sourceType = source
                controller.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
                controller.allowsEditing = true
                controller.delegate = mediaDelegate

                self?.navigationController?.present(controller, animated: true, completion: nil)
            }
        }
        chatViewController.onBackToQueue = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        chatViewController.onChatClosed = { [weak self] in
            self?.showRatingViewController()
        }

        return chatViewController
    }
}


// MARK: - NINChatViewController components

extension NINCoordinator {
    internal func chatDataSourceDelegate(_ viewModel: NINChatViewModel) -> NINChatDataSourceDelegate {
        var dataSourceDelegate: NINChatDataSourceDelegate = NINChatDataSourceDelegateImpl(viewModel: viewModel)
        dataSourceDelegate.onOpenPhotoAttachment = { [weak self] image, attachment in
            self?.showFullScreenViewController(image, attachment)
        }
        dataSourceDelegate.onOpenVideoAttachment = { attachment in
            guard let attachmentURL = attachment.url, let playerURL = URL(string: attachmentURL) else { return }
            let playerViewController = AVPlayerViewController()
            playerViewController.player = AVPlayer(url: playerURL)
            self.navigationController?.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
        return dataSourceDelegate
    }
        
    internal func chatRTCDelegate(_ videoDelegate: NINRTCVideoDelegate) -> NINWebRTCDelegate {
        return NINWebRTCDelegateImpl(remoteVideoDelegate: videoDelegate)
    }
    
    internal func chatMediaPicker(_ viewModel: NINChatViewModel) -> NINPickerControllerDelegate {
        return NINPickerControllerDelegateImpl(viewModel: viewModel)
    }
}
