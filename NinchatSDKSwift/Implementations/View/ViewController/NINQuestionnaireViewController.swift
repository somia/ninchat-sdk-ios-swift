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

final class NINQuestionnaireViewController: UIViewController, ViewController {

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
                        self?.updateConversationContentView(0.5)
                    }), 0.5)
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

    // MARK: - ViewController

    weak var session: NINChatSession?
    weak var sessionManager: NINChatSessionManager?

    // MARK: - Injected

    var queue: Queue?
    var style: QuestionnaireStyle!
    var dataSourceDelegate: QuestionnaireDataSourceDelegate? {
        didSet {
            dataSourceDelegate?.onUpdateCellContent = { [weak self] in
                guard let updateOperationTuple: (block: BlockOperation, _: TimeInterval) = self?.updateOperationBlock else { return }
                self?.operationQueue.addOperation(updateOperationTuple.block)
            }
            dataSourceDelegate?.onRemoveCellContent = { [weak self] in
                guard self?.style == .conversation else { return }
                self?.removeQuestionnaireSection()
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
                Toast.show(message: .error("Error is submitting the answers")) { [weak self] in
                    self?.session?.internalDelegate?.onDidEnd()
                }
            }
            viewModel.onQuestionnaireFinished = { [weak self] queue, exit in
                /// Complete questionnaire and navigate to the queue.
                if let queue = queue {
                    self?.completeQuestionnaire?(queue)
                }
                /// Finish the session if it is an `exit` element
                else if exit {
                    self?.viewModel.onSessionFinished?()
                }
                /// Show `AudienceRegisteredText` if it is set in the site configuration
                else if let registeredOperation = self?.audienceRegisteredOperation {
                    self?.showRegisteredPage(operation: registeredOperation)
                }
                /// If not, just finish the session
                else {
                    self?.viewModel.onSessionFinished?()
                }
            }
            viewModel.onSessionFinished = { [weak self] in
                if let ratingViewModel = self?.ratingViewModel, let weakSelf = self {
                    (weakSelf.rating != nil) ? ratingViewModel.rateChat(with: weakSelf.rating!) : ratingViewModel.skipRating()
                } else {
                    self?.session?.internalDelegate?.onDidEnd()
                }
            }
        }
    }
    var ratingViewModel: NINRatingViewModel?
    var rating: ChatStatus?
    var completeQuestionnaire: ((_ queue: Queue) -> Void)?

    // MARK: - SubViews

    private weak var contentView: UITableView? {
        didSet {
            guard let contentView = contentView else { return }
            self.view.addSubview(contentView)

            if #available(iOS 11, *) {
                contentView.fix(top: (0.0, self.view), bottom: (0.0, self.view), toSafeArea: true)
            } else {
                contentView.fix(top: (20.0, self.view), bottom: (0.0, self.view))
            }
            contentView
                    .fix(leading: (0, self.view), trailing: (0, self.view))
                    .backgroundColor = .clear
        }
    }
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        UIActivityIndicatorView(style: .gray)
    }()

    // MARK: - UIViewController life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.overrideAssets()
        self.addKeyboardListeners()
        self.initiateIndicatorView()

        /// let elements be loaded for a few seconds
        if self.style == .form { self.initiateFormContentView(0.5) }
        else if self.style == .conversation { self.initiateConversationContentView(1.0) }
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
    }

    private func overrideAssets() {
        if let backgroundImage = self.session?.internalDelegate?.override(imageAsset: .questionnaireBackground) {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else if let bundleImage = UIImage(named: "chat_background_pattern", in: .SDKBundle, compatibleWith: nil) {
            self.view.backgroundColor = UIColor(patternImage: bundleImage)
        }
    }

    private func generateTableView(isHidden: Bool) -> UITableView  {
        let view = UITableView(frame: .zero)
        view.register(ChatTypingCell.self)
        view.register(QuestionnaireCell.self)
        view.registerClass(QuestionnaireNavigationCell.self)

        view.separatorStyle = .none
        view.allowsSelection = false
        view.alpha = isHidden ? 0.0 : 1.0
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
        var newSection = -1
        let prepareOperation = BlockOperation {
            newSection = self.prepareSection()
            self.addLoadingRow(at: newSection)
            self.scrollToBottom(at: newSection)     /// Scroll to bottom
        }
        let updateContentViewOperation = BlockOperation { [weak self] in
            guard let contentView = self?.contentView else { return }

            self?.removeLoadingRow(at: newSection)
            contentView.beginUpdates()              /// Start loading questionnaires
            self?.addQuestionnaireRows(at: newSection)
            self?.addNavigationRow(at: newSection)
            contentView.endUpdates()                /// Finish loading questionnaires
            self?.scrollToBottom(at: newSection)     /// Scroll to bottom
        }

        updateContentViewOperation.addDependency(prepareOperation)
        self.dispatchQueue.asyncAfter(deadline: .now() + interval) { self.operationQueue.addOperation(updateContentViewOperation) }
        self.operationQueue.addOperation(prepareOperation)
    }

    func initiateConversationContentView(_ interval: TimeInterval) {
        self.contentView = self.generateTableView(isHidden: false)
        self.updateConversationContentView(interval)
    }

    private func scrollToBottom(at section: Int) {
        self.dispatchQueue.async {
            guard let contentView = self.contentView, contentView.numberOfSections > section, contentView.numberOfRows(inSection: section) >= 1 else { return }
            self.contentView?.scrollToRow(at: IndexPath(row: contentView.numberOfRows(inSection: section)-1, section: section), at: .bottom, animated: true)
        }
    }

    private func prepareSection() -> Int {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        let section = conversationDataSource.insertSection()
        contentView.insertSections(IndexSet(integer: section), with: .automatic)

        return section
    }

    private func addLoadingRow(at section: Int) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        conversationDataSource.isLoadingNewElements = true
        contentView.insertRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
    }

    private func removeLoadingRow(at section: Int) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("Not conformed") }
        conversationDataSource.isLoadingNewElements = false
        contentView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
    }

    private func addQuestionnaireRows(at section: Int) {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
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
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        do {
            _ = conversationDataSource.insertRow()
            let elements = try self.viewModel.getElements()
            contentView.insertRows(at: [IndexPath(row: elements.count, section: section)], with: .bottom)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func removeQuestionnaireSection() {
        guard let contentView = self.contentView, let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        contentView.deleteSections(IndexSet(integer: conversationDataSource.removeSection()), with: .fade)
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
        let height = self.dataSourceDelegate?.height(at: indexPath) ?? 0.0
        if self.style == .conversation {
            return height + ((indexPath.row == 0) ? 60.0 : 16.0)
        }
        return height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.dataSourceDelegate!.cell(at: indexPath, view: self.contentView!)
    }
}
