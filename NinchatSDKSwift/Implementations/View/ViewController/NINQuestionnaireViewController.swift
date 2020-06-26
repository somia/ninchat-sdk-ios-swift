//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable
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
    private var updateOperationBlock: BlockOperation?

    // MARK: - ViewController

    var session: NINChatSession!

    // MARK: - Injected

    var queue: Queue?
    var style: QuestionnaireStyle!
    var dataSourceDelegate: QuestionnaireDataSourceDelegate! {
        didSet {
            dataSourceDelegate.onUpdateCellContent = { [weak self] in
                guard let style = self?.style else { return }
                switch style {
                case .form:
                    self?.updateOperationBlock = BlockOperation {
                        self?.dispatchQueue.async { self?.updateFormContentView() }
                    }
                case .conversation:
                    self?.updateOperationBlock = BlockOperation {
                        self?.dispatchQueue.async { self?.updateConversationContentView(0.5) }
                    }
                }
                guard let updateOperationBlock = self?.updateOperationBlock else { return }
                self?.operationQueue.addOperation(updateOperationBlock)
            }
            dataSourceDelegate.onRemoveCellContent = { [weak self] in
                guard self?.style == .conversation else { return }
                self?.removeQuestionnaireSection()
            }
        }
    }
    var viewModel: NINQuestionnaireViewModel! {
        didSet {
            viewModel.onErrorOccurred = { [weak self] error in
                debugger("** ** SDK: error in registering audience: \(error)")
                /// Add 'audienceRegisteredClosedText' block operation
                /// The operation is called only when the dependency ('updateOperationBlock') is satisfied
                if let error = error as? NinchatError, error.title == "queue_is_closed", let updateOperationBlock = self?.updateOperationBlock {
                    let closedRegisteredOperation = BlockOperation {
                        _ = self?.dataSourceDelegate.addClosedRegisteredSection()
                    }
                    closedRegisteredOperation.addDependency(updateOperationBlock)
                    self?.operationQueue.addOperation(closedRegisteredOperation)
                    return
                }
                Toast.show(message: .error("Error is submitting the answers")) { [weak self] in
                    self?.session.onDidEnd()
                }
            }
            viewModel.onQuestionnaireFinished = { [weak self] queue, exit in
                if let queue = queue {
                    self?.completeQuestionnaire?(queue)
                } else if exit {
                    self?.viewModel.onSessionFinished?()
                } else {
                    _ = self?.dataSourceDelegate.addRegisterSection()
                }
            }
            viewModel.onSessionFinished = { [unowned self] in
                if let ratingViewModel = self.ratingViewModel {
                    (self.rating != nil) ? ratingViewModel.rateChat(with: self.rating!) : ratingViewModel.skipRating()
                } else {
                    self.session.onDidEnd()
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
        if let backgroundImage = self.session.override(imageAsset: .questionnaireBackground) {
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
            self?.dispatchQueue.asyncAfter(deadline: .now() + interval) {
                guard let contentView = self?.contentView else { return }

                self?.removeLoadingRow(at: newSection)
                contentView.beginUpdates()              /// Start loading questionnaires
                self?.addQuestionnaireRows(at: newSection)
                self?.addNavigationRow(at: newSection)
                contentView.endUpdates()                /// Finish loading questionnaires
                self?.scrollToBottom(at: newSection)     /// Scroll to bottom
            }
        }

        updateContentViewOperation.addDependency(prepareOperation)
        self.operationQueue.addOperations([prepareOperation, updateContentViewOperation], waitUntilFinished: false)
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
        guard let contentView = self.contentView, var conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        conversationDataSource.isLoadingNewElements = true
        contentView.insertRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
    }

    private func removeLoadingRow(at section: Int) {
        guard let contentView = self.contentView, var conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("Not conformed") }
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
        self.dataSourceDelegate.numberOfPages()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.dataSourceDelegate.numberOfMessages(in: section)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = self.dataSourceDelegate.height(at: indexPath)
        if self.style == .conversation {
            return height + ((indexPath.row == 0) ? 60.0 : 16.0)
        }
        return height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let contentView = self.contentView else { return UITableViewCell() }
        return self.dataSourceDelegate.cell(at: indexPath, view: contentView)
    }
}
