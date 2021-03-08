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

protocol Coordinator: class {
    init(with sessionManager: NINChatSessionManager, delegate: InternalDelegate?, onPresentationCompletion: @escaping (() -> Void))
    func start(with queue: String?, resume: ResumeMode?, within navigation: UINavigationController?) -> UIViewController?
    func prepareNINQuestionnaireViewModel(audienceMetadata: NINLowLevelClientProps?, onCompletion: @escaping (() -> Void))
    func deallocate()
}

final class NINCoordinator: NSObject, Coordinator, UIAdaptivePresentationControllerDelegate {

    // MARK: - Coordinator

    internal var delegate: InternalDelegate?
    internal var sessionManager: NINChatSessionManager!
    internal var onPresentationCompletion: (() -> Void)?
    internal weak var navigationController: UINavigationController? {
        didSet {
            if #available(iOS 13.0, *) {
                navigationController?.overrideUserInterfaceStyle = .light
            }
            navigationController?.presentationController?.delegate = self
        }
    }
    internal lazy var storyboard: UIStoryboard = {
        UIStoryboard(name: "Chat", bundle: .SDKBundle)
    }()
    private let dispatchGroup = DispatchGroup()

    // MARK: - Questionnaire helpers

    private var hasPreAudienceQuestionnaire: Bool {
        self.sessionManager.siteConfiguration?.preAudienceQuestionnaire?.count ?? 0 > 0
    }
    private var hasPostAudienceQuestionnaire: Bool {
        self.sessionManager.siteConfiguration?.postAudienceQuestionnaire?.count ?? 0 > 0
    }

    // MARK: - ViewControllers

    private var didLoaded_initialViewController = false
    internal lazy var initialViewController: NINInitialViewController = {
        let initialViewController: NINInitialViewController = storyboard.instantiateViewController()
        initialViewController.delegate = self.delegate
        initialViewController.sessionManager = self.sessionManager
        initialViewController.onQueueActionTapped = { [weak self] queue in
            DispatchQueue.main.async {
                guard let weakSelf = self else { return }
                weakSelf.navigationController?.pushViewController((weakSelf.hasPreAudienceQuestionnaire) ? weakSelf.questionnaireViewController(queue: queue, questionnaireType: .pre) : weakSelf.queueViewController(queue: queue), animated: true)
            }
        }

        didLoaded_initialViewController = true
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
    private var didLoaded_queueViewController = false
    internal lazy var queueViewController: NINQueueViewController = {
        let joinViewController: NINQueueViewController = storyboard.instantiateViewController()
        joinViewController.viewModel = NINQueueViewModelImpl(sessionManager: self.sessionManager, delegate: self.delegate)
        joinViewController.delegate = self.delegate
        joinViewController.sessionManager = sessionManager
        joinViewController.onQueueActionTapped = { [weak self] queue in
            DispatchQueue.main.async {
                guard let weakSelf = self else { return }
                weakSelf.navigationController?.pushViewController(weakSelf.chatViewController(queue: queue), animated: true)
            }
        }

        didLoaded_queueViewController = true
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
                guard let weakSelf = self else { return }
                let controller = UIImagePickerController()
                controller.sourceType = source
                controller.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
                controller.allowsEditing = true
                controller.delegate = mediaDelegate

                weakSelf.navigationController?.present(controller, animated: true, completion: nil)
            }
        }
        chatViewController.onBackToQueue = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        chatViewController.onChatClosed = { [weak self] in
            DispatchQueue.main.async {
                guard let weakSelf = self else { return }
                weakSelf.navigationController?.pushViewController(weakSelf.ratingViewController, animated: true)
            }
        }

        didLoaded_chatViewController = true
        return chatViewController
    }()
    private var didLoaded_fullScreenViewController = false
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

        didLoaded_fullScreenViewController = true
        return previewViewController
    }()
    private var didLoaded_ratingViewController = false
    internal lazy var ratingViewController: NINRatingViewController = {
        let viewModel: NINRatingViewModel = NINRatingViewModelImpl(sessionManager: self.sessionManager)
        let ratingViewController: NINRatingViewController = storyboard.instantiateViewController()
        ratingViewController.viewModel = viewModel
        ratingViewController.delegate = self.delegate
        ratingViewController.sessionManager = self.sessionManager
        ratingViewController.style = self.sessionManager.siteConfiguration?.postAudienceQuestionnaireStyle
        ratingViewController.onRatingFinished = { [weak self] (status: ChatStatus?) -> Bool in
            if !(self?.hasPostAudienceQuestionnaire ?? true) { return true }
            DispatchQueue.main.async {
                guard let weakSelf = self else { return }
                weakSelf.navigationController?.pushViewController(weakSelf.questionnaireViewController(ratingViewModel: viewModel, rating: status, questionnaireType: .post), animated: true)
            }
            return false
        }

        didLoaded_ratingViewController = true
        return ratingViewController
    }()

    // MARK: - Coordinator

    init(with sessionManager: NINChatSessionManager, delegate: InternalDelegate?, onPresentationCompletion: @escaping (() -> Void)) {
        self.sessionManager = sessionManager
        self.delegate = delegate
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

    /// In case of heavy questionnaires, there would be a memory-consuming job in instantiation of `NINQuestionnaireViewModel` even though it is implemented in a multi-thread manner using `OperationQueue`.
    /// Thus, we have to do the job in background before the questionnaire page being loaded
    func prepareNINQuestionnaireViewModel(audienceMetadata: NINLowLevelClientProps?, onCompletion: @escaping (() -> Void)) {
        if self.hasPreAudienceQuestionnaire {
            self.dispatchGroup.enter()
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.preQuestionnaireViewModel = NINQuestionnaireViewModelImpl(sessionManager: self?.sessionManager, audienceMetadata: audienceMetadata, questionnaireType: .pre)
                self?.dispatchGroup.leave()
            }
        }
        if self.hasPostAudienceQuestionnaire {
            self.dispatchGroup.enter()
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.postQuestionnaireViewModel = NINQuestionnaireViewModelImpl(sessionManager: self?.sessionManager, audienceMetadata: audienceMetadata, questionnaireType: .post)
                self?.dispatchGroup.leave()
            }
        }

        self.dispatchGroup.notify(queue: .global(qos: .background)) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onCompletion() }
        }
    }
}

extension NINCoordinator {
    internal func questionnaireViewController(queue: Queue? = nil, ratingViewModel: NINRatingViewModel? = nil, rating: ChatStatus? = nil, questionnaireType: AudienceQuestionnaireType) -> NINQuestionnaireViewController {
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
        vc.completeQuestionnaire = { [weak self] queue in
            DispatchQueue.main.async {
                guard let weakSelf = self, questionnaireType == .pre else { return }
                weakSelf.navigationController?.pushViewController(weakSelf.queueViewController(queue: queue), animated: true)
            }
        }
        self.preQuestionnaireViewModel?.queue = queue

        return vc
    }

    internal func queueViewController(resume: ResumeMode? = nil, queue: Queue?) -> NINQueueViewController {
        let vc = self.queueViewController
        vc.resumeMode = resume
        if let queue = queue { vc.queue = queue }
        else if case let .toQueue(target) = resume, let queue = target { vc.queue = queue }

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
                guard let weakSelf = self else { return }
                weakSelf.navigationController?.pushViewController(weakSelf.fullScreenViewController(image: image, attachment: attachment), animated: true)
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

// MARK: - UIAdaptivePresentationControllerDelegate

extension NINCoordinator {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.onPresentationCompletion?()
    }
}
