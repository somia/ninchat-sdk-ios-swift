//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import NinchatLowLevelClient

protocol QuestionnaireFormViewController {
    func initiateFormContentView(_ interval: TimeInterval)
    func updateFormContentView(_ interval: TimeInterval)
}
protocol QuestionnaireConversationController {
    func initiateConversationContentView(_ interval: TimeInterval)
    func updateConversationContentView(_ interval: TimeInterval)
}

final class NINQuestionnaireViewController: UIViewController, ViewController, KeyboardHandler, HasTitleBar {

    private let operationQueue = OperationQueue.main
    private let dispatchQueue = DispatchQueue.main

    private var updateOperationBlock: (BlockOperation, TimeInterval)? {
        switch style {
        case .form:
            return ((BlockOperation { [weak self] in
                        self?.updateFormContentView()
                    }), 0.0)
        case .conversation:
            return ((BlockOperation { [weak self] in
                        self?.updateConversationContentView(1.0)
                    }), 1.0)
        default:
            return nil
        }
    }
    private var audienceRegisteredOperation: BlockOperation? {
        guard self.dataSourceDelegate?.canAddRegisteredSection ?? false else { return nil }
        return BlockOperation { [weak self] in
            self?.dataSourceDelegate?.addRegisterSection()
        }
    }
    private var closedRegisteredOperation: BlockOperation? {
        guard self.dataSourceDelegate?.canAddClosedRegisteredSection ?? false else { return nil }
        return BlockOperation { [weak self] in
            self?.dataSourceDelegate?.addClosedRegisteredSection()
        }
    }

    // MARK: - KeyboardHandler

    var onKeyboardSizeChanged: ((CGFloat) -> Void)?

    // MARK: - ViewController

    weak var delegate: NINChatSessionInternalDelegate?
    weak var sessionManager: NINChatSessionManager?

    // MARK: - Injected

    var queue: Queue?
    var style: QuestionnaireStyle!
    var type: AudienceQuestionnaireType!
    var dataSourceDelegate: QuestionnaireDataSourceDelegate? {
        didSet {
            dataSourceDelegate?.onUpdateCellContent = { [weak self] in
                guard let updateOperationTuple: (block: BlockOperation, _: TimeInterval) = self?.updateOperationBlock else { return }
                self?.operationQueue.addOperation(updateOperationTuple.block)
            }
            dataSourceDelegate?.onRemoveCellContent = { [weak self] in
                guard self?.style == .conversation else { return }
                guard let updateOperationTuple: (_: BlockOperation, interval: TimeInterval) = self?.updateOperationBlock else { return }
                self?.removeQuestionnaireSection(updateOperationTuple.interval)
            }
        }
    }
    var viewModel: NINQuestionnaireViewModel! {
        didSet {
            viewModel.onErrorOccurred = { [weak self] error in
                debugger("** ** SDK: error in registering audience: \(error)")
                if let error = error as? NinchatError, error.type == "queue_is_closed" {
                    self?.showRegisteredPage(operation: self?.closedRegisteredOperation); return
                }
                Toast.show(message: .error("Submission Error".localized), onToastDismissed: { [weak self] in
                    self?.delegate?.onDidEnd()
                })
            }
            viewModel.onQuestionnaireFinished = { [weak self] queue, queueIsClosed, exit in
                /// Complete questionnaire and navigate to the queue.
                if let queue = queue {
                    self?.completeQuestionnaire?(queue)
                }
                /// Finish the session if it is an `exit` element
                else if exit {
                    self?.viewModel.onSessionFinished?()
                }
                /// Show `AudienceRegisteredText` if it is set in the site configuration
                /// and queue is NOT closed `https://github.com/somia/ninchat-ng/issues/1057`
                else if let registeredOperation = self?.audienceRegisteredOperation, !queueIsClosed {
                    self?.showRegisteredPage(operation: registeredOperation)
                }
                /// Show `AudienceRegisteredText` if it is set in the site configuration
                /// and queue is closed `https://github.com/somia/ninchat-ng/issues/1057`
                else if let closedOperation = self?.closedRegisteredOperation, queueIsClosed {
                    self?.showRegisteredPage(operation: closedOperation)
                }
                /// If not, just finish the session
                else {
                    self?.viewModel.onSessionFinished?()
                }
            }
            viewModel.onSessionFinished = { [weak self] in
                if let ratingViewModel = self?.ratingViewModel, let `self` = self {
                    (self.rating != nil) ? ratingViewModel.rateChat(with: self.rating!) : ratingViewModel.skipRating()
                } else {
                    self?.delegate?.onDidEnd()
                }
            }
        }
    }
    var ratingViewModel: NINRatingViewModel?
    var rating: ChatStatus?
    var completeQuestionnaire: ((_ queue: Queue) -> Void)?
    var cancelQuestionnaire: (() -> Void)?
    
    // MARK: - SubViews

    private weak var contentView: UITableView? {
        didSet {
            guard let contentView = contentView else { return }
            self.view.addSubview(contentView)

            contentView.estimatedRowHeight = 80.0
            contentView.rowHeight = UITableView.automaticDimension

            contentView
                    .fix(bottom: (0.0, self.view))
                    .fix(leading: (0, self.view), trailing: (0, self.view))
                    .backgroundColor = .clear

            if hasTitlebar {
                contentView.fix(top: (0.0, self.titlebar!), isRelative: true)
            } else {
                contentView.fix(top: (0, self.view), toSafeArea: true)
            }
        }
    }
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        UIActivityIndicatorView(style: .gray)
    }()

    /// MARK: - HasTitleBar

    @IBOutlet private(set) weak var titlebar: UIView?
    @IBOutlet private(set) weak var titlebarContainer: UIView?
    var hasTitlebar: Bool {
        /// questionnaire view has more logics for showing/hiding titlebar
        guard let session = self.sessionManager else {
            fatalError("session manager is not set!")
        }
        if session.siteConfiguration.hideTitlebar {
            return false
        }
        if type == .post, session.siteConfiguration.postAudienceQuestionnaireTitlebar == nil {
            return false
        }
        return true
    }
    var titlebarAvatar: String? {
        switch type {
        case .pre:
            return self.sessionManager?.siteConfiguration.audienceQuestionnaireAvatar as? String
        case .post:
            guard let config = sessionManager?.siteConfiguration.postAudienceQuestionnaireTitlebar else {
                return nil
            }

            switch config {
            case .agent:
                /// "agent": Display agent avatar/name/jobTitle
                ///     - agentAvatar:true, show user_attrs.iconurl everywhere
                ///     - agentAvatar:url, show that instead
                guard let avatar = self.sessionManager?.siteConfiguration.agentAvatar as? Bool else { return nil }
                return (self.sessionManager?.siteConfiguration.agentAvatar as? String) ?? (self.sessionManager?.agent?.iconURL)
            case .questionnaire:
                /// "questionnaire": Display questionnaireName and questionnaireAvatar
                return self.sessionManager?.siteConfiguration.audienceQuestionnaireAvatar as? String
            }
        default:
            return nil
        }
    }
    var titlebarName: String? {
        switch type {
        case .pre:
            return self.sessionManager?.siteConfiguration.audienceQuestionnaireUserName
        case .post:
            guard let config = sessionManager?.siteConfiguration.postAudienceQuestionnaireTitlebar else {
                return nil
            }

            switch config {
            case .agent:
                /// "agent": Display agent avatar/name/jobTitle
                return self.sessionManager?.siteConfiguration.agentName ?? self.sessionManager?.agent?.displayName
            case .questionnaire:
                /// "questionnaire": Display questionnaireName and questionnaireAvatar
                return self.sessionManager?.siteConfiguration.audienceQuestionnaireUserName
            }
        default:
            return nil
        }
    }
    var titlebarJob: String? {
        switch type {
        case .pre:
            return nil
        case .post:
            guard let config = sessionManager?.siteConfiguration.postAudienceQuestionnaireTitlebar else {
                return nil
            }

            switch config {
            case .agent:
                /// "agent": Display agent avatar/name/jobTitle
                return self.sessionManager?.agent?.info?.job
            case .questionnaire:
                return nil
            }
        default:
            return nil
        }
    }

    // MARK: - UIViewController life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitleBar(parent: nil, adjustToSafeArea: true) { [weak self] in
            self?.cancelQuestionnaire?()
        }
        self.overrideAssets()
        self.addKeyboardListeners()
        self.initiateIndicatorView()

        /// let elements be loaded for a few seconds
        if self.style == .form { self.initiateFormContentView(0.5) }
        else if self.style == .conversation { self.initiateConversationContentView(1.0) }

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        self.navigationItem.setHidesBackButton(true, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.deallocate()
    }

    deinit {
        self.deallocate()
    }

    func deallocate() {
        debugger("`NINQuestionnaireViewController` deallocated")

        self.operationQueue.cancelAllOperations()
        self.removeKeyboardListeners()
        self.contentView = nil

        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func overrideAssets() {
        overrideTitlebarAssets()

        if let backgroundImage = self.delegate?.override(imageAsset: .ninchatQuestionnaireBackground) {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else if let bundleImage = UIImage(named: "chat_background_pattern", in: .SDKBundle, compatibleWith: nil) {
            self.view.backgroundColor = UIColor(patternImage: bundleImage)
        }
    }

    private func generateTableView(isHidden: Bool) -> UITableView  {
        let view = UITableView(frame: .zero)
        view.register(QuestionnaireCell.self)
        view.register(QuestionnaireLoadingCell.self)
        view.registerClass(QuestionnaireNavigationCell.self)

        view.separatorStyle = .none
        view.allowsSelection = false
        view.alpha = isHidden ? 0.0 : 1.0
        view.sectionHeaderHeight = 0.0
        view.delegate = self
        view.dataSource = self

        return view
    }

    private func showRegisteredPage(operation: BlockOperation?) {
        guard let operation = operation, let updateOperationTuple: (block: BlockOperation, delay: TimeInterval) = self.updateOperationBlock else { return }
        self.operationQueue.addOperation(updateOperationTuple.block)

        operation.addDependency(updateOperationTuple.block)
        self.dispatchQueue.asyncAfter(deadline: .now() + updateOperationTuple.delay) { self.operationQueue.addOperation(operation) }
    }
}

// MARK: - 'Form Like' questionnaires
extension NINQuestionnaireViewController: QuestionnaireFormViewController {
    func updateFormContentView(_ interval: TimeInterval = 0.0) {
        self.view.endEditing(true)
        
        self.loadingIndicator.startAnimating()
        contentView?.hide(true, andCompletion: { [weak self] in
            self?.contentView?.removeFromSuperview()
            self?.initiateFormContentView(interval)
        })
    }

    func initiateFormContentView(_ interval: TimeInterval) {
        self.loadingIndicator.startAnimating()
        self.dispatchQueue.asyncAfter(deadline: .now() + interval) {
            self.contentView = self.generateTableView(isHidden: true)
            self.contentView?.hide(false, andCompletion: { [weak self] in
                self?.loadingIndicator.stopAnimating()
            })
        }
    }

    private func initiateIndicatorView() {
        self.loadingIndicator.hidesWhenStopped = true
        self.loadingIndicator.stopAnimating()

        self.view.addSubview(self.loadingIndicator)
        self.loadingIndicator.center(toX: self.view, toY: self.view)
    }
}

// MARK: - 'Conversation Like' questionnaires
extension NINQuestionnaireViewController: QuestionnaireConversationController {
    func updateConversationContentView(_ interval: TimeInterval = 0.0) {
        self.view.endEditing(true)

        var newSection = -1
        let prepareOperation = BlockOperation { [weak self] in
            guard let `self` = self else { return }

            newSection = self.prepareSection()
            self.addLoadingRow(at: newSection)
            self.scrollToBottom(at: newSection, delay: 0.0)     /// Scroll to bottom
        }
        let removeLoadingRowOperation = BlockOperation { [weak self] in
            self?.removeLoadingRow(at: newSection)
        }
        let updateContentViewOperation = BlockOperation { [weak self] in
            guard let weakSelf = self, let contentView = weakSelf.contentView else { return }

            contentView.beginUpdates()              /// Start loading questionnaires
            weakSelf.addQuestionnaireRows(at: newSection)
            weakSelf.addNavigationRow(at: newSection)
            contentView.endUpdates()                /// Finish loading questionnaires
            weakSelf.scrollToBottom(at: newSection, delay: 0.5)     /// Scroll to bottom
        }

        updateContentViewOperation.addDependency(prepareOperation)
        updateContentViewOperation.addDependency(removeLoadingRowOperation)
        self.dispatchQueue.asyncAfter(deadline: .now() + interval) { self.operationQueue.addOperation(removeLoadingRowOperation) }
        self.dispatchQueue.asyncAfter(deadline: .now() + interval) { self.operationQueue.addOperation(updateContentViewOperation) }
        self.operationQueue.addOperation(prepareOperation)
    }

    func initiateConversationContentView(_ interval: TimeInterval) {
        self.contentView = self.generateTableView(isHidden: false)
        self.updateConversationContentView(interval)
    }

    private func scrollToBottom(at section: Int, delay: Double) {
        self.dispatchQueue.asyncAfter(deadline: .now() + delay) {
            guard let contentView = self.contentView, contentView.numberOfSections > section, contentView.numberOfRows(inSection: section) >= 1 else { return }
            self.contentView?.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true)
        }
    }

    private func prepareSection() -> Int {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` is not conformed to `QuestionnaireConversationHelpers`") }
        let section = conversationDataSource.insertSection()
        contentView.insertSections(IndexSet(integer: section), with: .automatic)
        if section > 0 { contentView.reloadSections(IndexSet(integer: section-1), with: .none) }
        return section
    }

    private func addLoadingRow(at section: Int) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers
            else { fatalError("`dataSourceDelegate` is not conformed to `QuestionnaireConversationHelpers`") }

        conversationDataSource.isLoadingNewElements = true
        contentView.insertRows(at: [IndexPath(row: 0, section: section)], with: .fade)
    }

    private func removeLoadingRow(at section: Int) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers
            else { fatalError("Not conformed") }

        conversationDataSource.isLoadingNewElements = false
        contentView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .fade)
    }

    private func addQuestionnaireRows(at section: Int) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers
            else { fatalError("`dataSourceDelegate` is not conformed to `QuestionnaireConversationHelpers`") }

        do {
            let elements = try self.viewModel.getElements()
            elements.forEach { element in
                contentView.insertRows(at: [IndexPath(row: elements.firstIndex(where: { $0 == element })!, section: section)], with: .bottom)
                _ = conversationDataSource.insertRow()
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func addNavigationRow(at section: Int) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` is not conformed to `QuestionnaireConversationHelpers`") }
        do {
            _ = conversationDataSource.insertRow()
            let elements = try self.viewModel.getElements()
            contentView.insertRows(at: [IndexPath(row: elements.count, section: section)], with: .bottom)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func removeQuestionnaireSection(_ interval: TimeInterval) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers
            else { fatalError("`dataSourceDelegate` is not conformed to `QuestionnaireConversationHelpers`") }

        let section = conversationDataSource.removeSection()
        let removeOperation = BlockOperation { [weak self] in
            self?.dispatchQueue.async {
                contentView.deleteSections(IndexSet(integer: section), with: .top)
            }
        }
        let updateOperation = BlockOperation { [weak self] in
            self?.dispatchQueue.async {
                contentView.reloadSections(IndexSet(integer: section-1), with: .none)
            }
        }

        updateOperation.addDependency(removeOperation)
        self.dispatchQueue.asyncAfter(deadline: .now() + interval) { self.operationQueue.addOperation(updateOperation) }
        self.operationQueue.addOperation(removeOperation)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension NINQuestionnaireViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        self.dataSourceDelegate?.numberOfPages() ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.dataSourceDelegate?.numberOfMessages(in: section) ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let component = self.dataSourceDelegate?.cellHeightComponent(at: indexPath) else {
            return UITableView.automaticDimension
        }

        if component.type == nil, component.isLoading {
            /// Loading cell
            return component.height
        } else if component.type == nil, !component.isLoading {
            /// navigation cell
            return component.height
        } else if component.type is QuestionnaireElementText.Type {
            /// Text element cell
            return UITableView.automaticDimension
        } else {
            /// Other elements
            let height = component.height
            if self.style == .conversation {
                return height + ((indexPath.row == 0) ? 55.0 : 0.0)
            }
            return height
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.dataSourceDelegate!.cell(at: indexPath, view: self.contentView!)
    }
}

extension NINQuestionnaireViewController {
    @objc
    private func didEnterBackground(notification: Notification) {
        self.view.endEditing(true)
    }
}
