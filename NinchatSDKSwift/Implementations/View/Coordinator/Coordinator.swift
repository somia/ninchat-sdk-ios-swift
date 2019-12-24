//
//  AppCoordinator.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit
import CoreServices
import AVFoundation
import AVKit
import NinchatSDK

protocol Coordinator: class {
    init(with session: NINChatSessionSwift)
    func start(with queue: String?, within navigation: UINavigationController) -> UIViewController?
}

final class NINCoordinator: Coordinator {
    
    // MARK: - Coordinator
    
    internal unowned let session: NINChatSessionSwift
    internal var navigationController: UINavigationController?
    internal var storyboard: UIStoryboard {
        return UIStoryboard(name: "Chat", bundle: .SDKBundle)
    }
    
    init(with session: NINChatSessionSwift) {
        self.session = session
    }
    
    func start(with queue: String?, within navigation: UINavigationController) -> UIViewController? {
        self.navigationController = navigation
        if let queue = queue {
            return joinAutomatically(for: queue)
        }
        return showJoinOptions()
    }
}

// MARK: - Navigation

extension NINCoordinator {
    internal func joinAutomatically(for queue: String) -> UIViewController? {
        guard let target = session.sessionManager.queues.filter({ $0.queueID == queue }).first else {
            return nil
        }
        return joinDirectly(to: target)
    }
    
    internal func showQueueViewController(for queue: NINQueue?) {
        guard let target = queue, let queueVC = joinDirectly(to: target) else { return }
        self.navigationController?.pushViewController(queueVC, animated: true)
    }
    
    @discardableResult
    internal func showChatViewController() -> UIViewController {
        let viewModel: NINChatViewModel = NINChatViewModelImpl(session: self.session)
        let chatViewController: NINChatViewController = storyboard.instantiateViewController()
        chatViewController.viewModel = viewModel
        chatViewController.session = session
        chatViewController.onOpenGallery = { [weak self] source, delegate in
            let controller = UIImagePickerController()
            controller.sourceType = source
            controller.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
            controller.allowsEditing = true
            controller.delegate = delegate

            self?.navigationController?.present(controller, animated: true, completion: nil)
        }
        chatViewController.onOpenPhotoAttachment = { [weak self] image, attachment in
            self?.showFullScreenViewController(image, attachment)
        }
        chatViewController.onOpenVideoAttachment = { attachment in
            guard let attachmentURL = attachment.url, let playerURL = URL(string: attachmentURL) else { return }
            let playerViewController = AVPlayerViewController()
            playerViewController.player = AVPlayer(url: playerURL)
            self.navigationController?.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
        chatViewController.onBackToQueue = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        chatViewController.onChatClosed = { [weak self] in
            self?.showRatingViewController()
        }
        
        self.navigationController?.pushViewController(chatViewController, animated: true)
        return chatViewController
    }
    
    @discardableResult
    internal func showFullScreenViewController(_ image: UIImage, _ attachment: NINFileInfo) -> UIViewController? {
        let viewModel: NINFullScreenViewModel = NINFullScreenViewModelImpl(session: self.session)
        let previewViewController: NINFullScreenViewController = storyboard.instantiateViewController()
        previewViewController.viewModel = viewModel
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
        let viewModel: NINRatingViewModel = NINRatingViewModelImpl(session: self.session)
        let ratingViewController: NINRatingViewController = storyboard.instantiateViewController()
        ratingViewController.session = session
        ratingViewController.viewModel = viewModel
        
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
    internal func joinDirectly(to queue: NINQueue) -> UIViewController? {
        let viewModel: NINQueueViewModel = NINQueueViewModelImpl(session: self.session, queue: queue)
        let joinViewController: NINQueueViewController = storyboard.instantiateViewController()
        joinViewController.session = session
        joinViewController.viewModel = viewModel
        joinViewController.onQueueActionTapped = { [weak self] in
            self?.showChatViewController()
        }
        
        return joinViewController
    }
}
