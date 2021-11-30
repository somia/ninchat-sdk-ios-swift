//
// Copyright (c) 4.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AVKit
import CoreServices
import WebRTC
import NinchatLowLevelClient

protocol Coordinator: AnyObject {
    init(with sessionManager: NINChatSessionManager, delegate: NINChatSessionInternalDelegate?, onPresentationCompletion: @escaping () -> Void)
    func start(with queue: String?, resume: ResumeMode?, within navigation: UINavigationController?) -> UIViewController?
    func prepareNINQuestionnaireViewModel(onCompletion: @escaping () -> Void)
    func deallocate()
}

final class NINCoordinator: NSObject, Coordinator, UIAdaptivePresentationControllerDelegate {

    // MARK: - Coordinator

    internal weak var delegate: NINChatSessionInternalDelegate?
    internal weak var sessionManager: NINChatSessionManager!
    internal var onPresentationCompletion: (() -> Void)?
    internal weak var navigationController: UINavigationController? {
        didSet {
            if #available(iOS 13.0, *) {
                navigationController?.overrideUserInterfaceStyle = .light
            }

            if !self.sessionManager.siteConfiguration.hideTitlebar {
                navigationController?.setNavigationBarHidden(true, animated: false)
            }
            navigationController?.presentationController?.delegate = self
        }
    }
    internal lazy var storyboard: UIStoryboard = {
        UIStoryboard(name: "Chat", bundle: .SDKBundle)
    }()
    
    // MARK: - Questionnaire helpers

    private var hasPreAudienceQuestionnaire: Bool {
        self.sessionManager.siteConfiguration?.preAudienceQuestionnaire?.count ?? 0 > 0
    }
    private var hasPostAudienceQuestionnaire: Bool {
        self.sessionManager.siteConfiguration?.postAudienceQuestionnaire?.count ?? 0 > 0
    }
    private let operationQueue = OperationQueue.main
    private let dispatchQueue = DispatchQueue.main
    
    // MARK: - ViewControllers

    internal lazy var initialViewController: NINInitialViewController = {
        let initialViewController: NINInitialViewController = storyboard.instantiateViewController()
        initialViewController.delegate = self.delegate
        initialViewController.sessionManager = self.sessionManager
        initialViewController.onQueueActionTapped = { [weak self] queue in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                
                var viewController: UIViewController
                if self.hasPreAudienceQuestionnaire {
                    viewController = self.questionnaireViewController(queue: queue, questionnaireType: .pre)
                } else {
                    viewController = self.queueViewController(queue: queue)
                }
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }

        return initialViewController
    }()
    /// Since it is pushed more than once, it cannot be defined as `lazy`
    private var didLoaded_questionnaireViewController = false
    private var preQuestionnaireViewModel: NINQuestionnaireViewModel!
    private var postQuestionnaireViewModel: NINQuestionnaireViewModel!
    internal var questionnaireViewController: NINQuestionnaireViewController {
        let questionnaireViewController: NINQuestionnaireViewController = storyboard.instantiateViewController()
        questionnaireViewController.delegate = self.delegate
        questionnaireViewController.sessionManager = self.sessionManager

        didLoaded_questionnaireViewController = true
        return questionnaireViewController
    }
    internal lazy var queueViewController: NINQueueViewController = {
        let joinViewController: NINQueueViewController = storyboard.instantiateViewController()
        joinViewController.viewModel = NINQueueViewModelImpl(sessionManager: self.sessionManager, delegate: self.delegate)
        joinViewController.delegate = self.delegate
        joinViewController.sessionManager = sessionManager
        joinViewController.onQueueActionTapped = { [weak self] queue in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.navigationController?.pushViewController(self.chatViewController(queue: queue), animated: true)
            }
        }

        return joinViewController
    }()
    private var didLoaded_chatViewController = false
    internal lazy var chatViewController: NINChatViewController = {
        let viewModel: NINChatViewModel = NINChatViewModelImpl(sessionManager: self.sessionManager)
        let videoDelegate: NINRTCVideoDelegate = NINRTCVideoDelegateImpl()
        let mediaDelegate: NINPickerControllerDelegate = chatMediaPicker(viewModel)
        let chatViewController: NINChatViewController = storyboard.instantiateViewController()
        chatViewController.viewModel = viewModel
        chatViewController.delegate = self.delegate
        chatViewController.sessionManager = self.sessionManager
        chatViewController.chatDataSourceDelegate = chatDataSourceDelegate(viewModel)
        chatViewController.chatVideoDelegate = videoDelegate
        chatViewController.chatRTCDelegate = chatRTCDelegate(videoDelegate)
        chatViewController.chatMediaPickerDelegate = mediaDelegate

        chatViewController.onOpenGallery = { [weak self] source in
            DispatchQueue.main.async {
                guard let `self` = self else { return }

                let controller = UIImagePickerController()
                controller.sourceType = source
                controller.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
                controller.allowsEditing = false
                controller.videoQuality = .typeMedium
                controller.delegate = mediaDelegate
                self.navigationController?.present(controller, animated: true, completion: nil)
            }
        }
        chatViewController.onBackToQueue = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        chatViewController.onChatClosed = { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.navigationController?.pushViewController(self.ratingViewController, animated: true)
            }
        }

        didLoaded_chatViewController = true
        return chatViewController
    }()
    internal lazy var fullScreenViewController: NINFullScreenViewController = {
        let viewModel: NINFullScreenViewModel = NINFullScreenViewModelImpl(delegate: nil)
        let previewViewController: NINFullScreenViewController = storyboard.instantiateViewController()
        previewViewController.viewModel = viewModel
        previewViewController.delegate = self.delegate
        previewViewController.sessionManager = self.sessionManager
        previewViewController.onCloseTapped = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }

        return previewViewController
    }()
    internal lazy var ratingViewController: NINRatingViewController = {
        let viewModel: NINRatingViewModel = NINRatingViewModelImpl(sessionManager: self.sessionManager)
        let ratingViewController: NINRatingViewController = storyboard.instantiateViewController()
        ratingViewController.viewModel = viewModel
        ratingViewController.delegate = self.delegate
        ratingViewController.sessionManager = self.sessionManager
        ratingViewController.style = self.sessionManager.siteConfiguration?.postAudienceQuestionnaireStyle
        ratingViewController.onRatingFinished = { [weak self] (status: ChatStatus?) -> Bool in
            guard let `self` = self else { return true }
            
            /// skip post questionnaire if the user skip rating.
            /// according to `https://github.com/somia/mobile/issues/342`
            if status == nil { return true }
            
            if !self.hasPostAudienceQuestionnaire { return true }
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(self.questionnaireViewController(ratingViewModel: viewModel, rating: status, questionnaireType: .post), animated: true)
            }
            return false
        }

        return ratingViewController
    }()

    // MARK: - Coordinator

    init(with sessionManager: NINChatSessionManager, delegate: NINChatSessionInternalDelegate?, onPresentationCompletion: @escaping () -> Void) {
        self.delegate = delegate
        self.sessionManager = sessionManager
        self.onPresentationCompletion = onPresentationCompletion
    }

    func start(with queue: String?, resume: ResumeMode?, within navigation: UINavigationController?) -> UIViewController? {
        let topViewController: UIViewController
        if let resume = resume {
            topViewController = self.queueViewController(resume: resume, queue: nil)
        } else if let queue = queue, let target = self.sessionManager.queues.filter({ $0.queueID == queue }).first {
            topViewController = hasPreAudienceQuestionnaire ? self.questionnaireViewController(queue: target, questionnaireType: .pre) : self.queueViewController(queue: target)
        } else {
            topViewController = self.initialViewController
        }
        self.navigationController = navigation ?? UINavigationController(rootViewController: topViewController)
        return (navigation == nil) ? self.navigationController : topViewController
    }

    func deallocate() {
        if self.didLoaded_questionnaireViewController { self.questionnaireViewController.deallocate() }
        if self.didLoaded_chatViewController { self.chatViewController.deallocate() }
    }

    /// In case of heavy questionnaires, there would be a memory-consuming job in instantiation of `NINQuestionnaireViewModel`
    /// even though it is implemented in a multi-thread manner using `OperationQueue`.
    /// Thus, we have to do the job in background before the questionnaire page being loaded
    func prepareNINQuestionnaireViewModel(onCompletion: @escaping () -> Void) {
        let completionOperation = BlockOperation {
            onCompletion()
        }
        
        if self.hasPreAudienceQuestionnaire {
            let operation = BlockOperation { [weak self] in
                self?.preQuestionnaireViewModel = NINQuestionnaireViewModelImpl(sessionManager: self?.sessionManager, questionnaireType: .pre)
            }
            
            completionOperation.addDependency(operation)
            self.operationQueue.addOperation(operation)
        }
        if self.hasPostAudienceQuestionnaire {
            let operation = BlockOperation { [weak self] in
                self?.postQuestionnaireViewModel = NINQuestionnaireViewModelImpl(sessionManager: self?.sessionManager, questionnaireType: .post)
            }
            
            completionOperation.addDependency(operation)
            self.operationQueue.addOperation(operation)
        }
        
        self.dispatchQueue.asyncAfter(deadline: .now() + 0.2) { self.operationQueue.addOperation(completionOperation) }
    }
}

extension NINCoordinator {
    internal func questionnaireViewController(queue: Queue? = nil, ratingViewModel: NINRatingViewModel? = nil,
                                              rating: ChatStatus? = nil, questionnaireType: AudienceQuestionnaireType) -> NINQuestionnaireViewController {
        let vc = self.questionnaireViewController
        vc.queue = queue
        vc.rating = rating
        vc.ratingViewModel = ratingViewModel
        vc.viewModel = (questionnaireType == .pre) ? self.preQuestionnaireViewModel : self.postQuestionnaireViewModel

        let style = self.sessionManager.siteConfiguration.preAudienceQuestionnaireStyle
        switch style {
        case .form:
            vc.dataSourceDelegate = NINQuestionnaireFormDataSourceDelegate(viewModel: (questionnaireType == .pre) ? self.preQuestionnaireViewModel : self.postQuestionnaireViewModel, sessionManager: self.sessionManager, delegate: self.delegate)
        case .conversation:
            vc.dataSourceDelegate = NINQuestionnaireConversationDataSourceDelegate(viewModel: (questionnaireType == .pre) ? self.preQuestionnaireViewModel : self.postQuestionnaireViewModel, sessionManager: self.sessionManager, delegate: self.delegate)
        }
        vc.style = style
        vc.type = questionnaireType
        vc.completeQuestionnaire = { [weak self] queue, backlogMessage in
            DispatchQueue.main.async {
                guard let `self` = self, questionnaireType == .pre else { return }
                self.navigationController?.pushViewController(self.queueViewController(queue: queue), animated: true)
            }
        }
        vc.cancelQuestionnaire = { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }

                if self.navigationController?.topViewController is NINInitialViewController {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    /// SDK started with AutoQueue and thus,
                    /// the questionnaire has no previous ViewController to pop to.

                    self.delegate?.onDidEnd()
                }
            }
        }
        self.preQuestionnaireViewModel?.queue = queue

        return vc
    }

    internal func queueViewController(resume: ResumeMode? = nil, queue: Queue?) -> NINQueueViewController {
        let vc = self.queueViewController
        vc.resumeMode = resume
        if let queue = queue {
            vc.queue = queue
        } else if case let .toQueue(target) = resume, let queue = target {
            vc.queue = queue
        }

        return vc
    }

    internal func chatViewController(queue: Queue?) -> NINChatViewController {
        let vc = self.chatViewController
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
        let dataSourceDelegate: NINChatDataSourceDelegate = NINChatDataSourceDelegateImpl(viewModel: viewModel)
        dataSourceDelegate.onOpenPhotoAttachment = { [weak self] image, attachment in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.navigationController?.pushViewController(self.fullScreenViewController(image: image, attachment: attachment), animated: true)
            }
        }
        dataSourceDelegate.onOpenVideoAttachment = { [weak self] attachment in
            guard let attachmentURL = attachment.url, let playerURL = URL(string: attachmentURL) else { return }
            
            let playerViewController = AVPlayerViewController()
            playerViewController.player = AVPlayer(url: playerURL)
            
            self?.navigationController?.present(playerViewController, animated: true) {
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

// MARK: - UIAdaptivePresentationControllerDelegate

extension NINCoordinator {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.onPresentationCompletion?()
    }
}
