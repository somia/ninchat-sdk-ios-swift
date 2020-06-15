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
    init(with session: NINChatSession)
    func start(with queue: String?, resumeSession: Bool, within navigation: UINavigationController?) -> UIViewController?
    func deallocate()
}

final class NINCoordinator: Coordinator {
    
    // MARK: - Coordinator
    
    internal unowned let session: NINChatSession
    internal weak var navigationController: UINavigationController? {
        didSet {
            if #available(iOS 13.0, *) {
                navigationController?.overrideUserInterfaceStyle = .light
            }
        }
    }
    internal var storyboard: UIStoryboard {
        UIStoryboard(name: "Chat", bundle: .SDKBundle)
    }
    internal var sessionManager: NINChatSessionManager {
        session.sessionManager
    }

    // MARK: - Questionnaire helpers

    private var hasPreAudienceQuestionnaire: Bool {
        self.sessionManager.siteConfiguration.preAudienceQuestionnaire?.count ?? 0 > 0
    }
    private var hasPostAudienceQuestionnaire: Bool {
        self.sessionManager.siteConfiguration.postAudienceQuestionnaire?.count ?? 0 > 0
    }

    // MARK: - ViewControllers

    internal lazy var initialViewController: NINInitialViewController = {
        let initialViewController: NINInitialViewController = storyboard.instantiateViewController()
        initialViewController.session = session
        initialViewController.onQueueActionTapped = { [unowned self] queue in
            DispatchQueue.main.async {
                self.navigationController?.pushViewController((self.hasPreAudienceQuestionnaire) ? self.questionnaireViewController(queue: queue, questionnaireType: .pre) : self.queueViewController(queue: queue), animated: true)
            }
        }

        return initialViewController
    }()
    /// Since it is pushed more than once, it cannot be defined as `lazy`
    internal var questionnaireViewController: NINQuestionnaireViewController {
        storyboard.instantiateViewController()
    }
    internal lazy var queueViewController: NINQueueViewController = {
        let joinViewController: NINQueueViewController = storyboard.instantiateViewController()
        joinViewController.viewModel = NINQueueViewModelImpl(sessionManager: self.sessionManager, delegate: self.session)
        joinViewController.session = session
        joinViewController.onQueueActionTapped = { [unowned self] in
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(self.chatViewController, animated: true)
            }
        }

        return joinViewController
    }()
    internal lazy var chatViewController: NINChatViewController = {
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

        chatViewController.onOpenGallery = { [unowned self] source in
            let controller = UIImagePickerController()
            controller.sourceType = source
            controller.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
            controller.allowsEditing = true
            controller.delegate = mediaDelegate

            DispatchQueue.main.async {
                self.navigationController?.present(controller, animated: true, completion: nil)
            }
        }
        chatViewController.onBackToQueue = { [unowned self] in
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
        chatViewController.onChatClosed = { [unowned self] in
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(self.ratingViewController, animated: true)
            }
        }

        return chatViewController
    }()
    internal lazy var fullScreenViewController: NINFullScreenViewController = {
        let viewModel: NINFullScreenViewModel = NINFullScreenViewModelImpl(delegate: self.session)
        let previewViewController: NINFullScreenViewController = storyboard.instantiateViewController()
        previewViewController.viewModel = viewModel
        previewViewController.session = session
        previewViewController.onCloseTapped = { [unowned self] in
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }

        return previewViewController
    }()
    internal lazy var ratingViewController: NINRatingViewController = {
        let viewModel: NINRatingViewModel = NINRatingViewModelImpl(sessionManager: self.sessionManager)
        let ratingViewController: NINRatingViewController = storyboard.instantiateViewController()
        ratingViewController.session = session
        ratingViewController.viewModel = viewModel
        ratingViewController.translate = sessionManager
        ratingViewController.onRatingFinished = { [unowned self] (status: ChatStatus?) -> Bool in
            if !self.hasPostAudienceQuestionnaire { return true }
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(self.questionnaireViewController(ratingViewModel: viewModel, rating: status, questionnaireType: .post), animated: true)
            }
            return false
        }

        return ratingViewController
    }()

    // MARK: - Coordinator

    init(with session: NINChatSession) {
        self.session = session
    }
    
    func start(with queue: String?, resumeSession: Bool, within navigation: UINavigationController?) -> UIViewController? {
        let topViewController: UIViewController
        if resumeSession {
            topViewController = self.queueViewController(resume: resumeSession)
        } else if let queue = queue, let target = self.sessionManager.queues.filter({ $0.queueID == queue }).first, !hasPreAudienceQuestionnaire {
            topViewController = self.queueViewController(queue: target)
        } else {
            topViewController = self.initialViewController
        }
        self.navigationController = navigation ?? UINavigationController(rootViewController: topViewController)
        return (navigation == nil) ? self.navigationController : topViewController
    }

    func deallocate() {
        self.chatViewController.deallocate()
    }
}

extension NINCoordinator {
    internal func questionnaireViewController(queue: Queue? = nil, ratingViewModel: NINRatingViewModel? = nil, rating: ChatStatus? = nil, questionnaireType: AudienceQuestionnaireType) -> NINQuestionnaireViewController {
        let vc = self.questionnaireViewController
        vc.queue = queue
        vc.session = session
        vc.rating = rating
        vc.ratingViewModel = ratingViewModel

        let viewModel = NINQuestionnaireViewModelImpl(sessionManager: self.sessionManager, queue: queue, questionnaireType: questionnaireType)
        switch self.session.sessionManager.siteConfiguration.preAudienceQuestionnaireStyle {
        case .form:
            vc.dataSourceDelegate = NINQuestionnaireFormDataSourceDelegate(viewModel: viewModel, session: self.session)
        case .conversation:
            vc.dataSourceDelegate = NINQuestionnaireConversationDataSourceDelegate(viewModel: viewModel, session: self.session)
        }
        vc.viewModel = viewModel
        vc.completeQuestionnaire = { [unowned self] queue in
            DispatchQueue.main.async {
                if questionnaireType == .pre {
                    self.navigationController?.pushViewController(self.queueViewController(queue: queue), animated: true)
                }
            }
        }

        return vc
    }

    internal func queueViewController(resume: Bool) -> NINQueueViewController {
        let vc = self.queueViewController
        vc.resumeMode = resume

        return vc
    }

    internal func queueViewController(queue: Queue) -> NINQueueViewController {
        let vc = self.queueViewController
        vc.resumeMode = false
        vc.queue = queue

        return vc
    }

    internal func fullScreenViewController(image: UIImage?, attachment: FileInfo?) -> NINFullScreenViewController {
        let vc = self.fullScreenViewController
        vc.image = image
        vc.attachment = attachment

        return vc
    }
}

// MARK: - NINChatViewController components

extension NINCoordinator {
    internal func chatDataSourceDelegate(_ viewModel: NINChatViewModel) -> NINChatDataSourceDelegate {
        var dataSourceDelegate: NINChatDataSourceDelegate = NINChatDataSourceDelegateImpl(viewModel: viewModel)
        dataSourceDelegate.onOpenPhotoAttachment = { [unowned self] image, attachment in
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(self.fullScreenViewController(image: image, attachment: attachment), animated: true)
            }
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
        NINWebRTCDelegateImpl(remoteVideoDelegate: videoDelegate)
    }
    
    internal func chatMediaPicker(_ viewModel: NINChatViewModel) -> NINPickerControllerDelegate {
        NINPickerControllerDelegateImpl(viewModel: viewModel)
    }
}
