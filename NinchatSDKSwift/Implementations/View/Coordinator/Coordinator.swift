//
//  AppCoordinator.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 4.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit
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
            
        }
        
        return joinViewController
    }
}
