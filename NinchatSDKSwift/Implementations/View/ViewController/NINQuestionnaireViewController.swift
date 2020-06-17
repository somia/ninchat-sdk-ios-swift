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
                    self?.updateFormContentView()
                case .conversation:
                    self?.updateConversationContentView(1.0)
                }
            }
            dataSourceDelegate.onRemoveCellContent = { [weak self] in
                guard self?.style == .conversation else { return }
                self?.removeQuestionnaireSection()
            }
        }
    }
    var viewModel: NINQuestionnaireViewModel! {
        didSet {
            viewModel.onErrorOccurred = { error in
                debugger("** ** SDK: error in registering audience: \(error)")
                Toast.show(message: .error("Error is submitting the answers")) { [weak self] in
                    self?.session.onDidEnd()
                }
            }
            viewModel.onQuestionnaireFinished = { [weak self] queue in
                self?.completeQuestionnaire?(queue)
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

    private var contentView: UITableView! {
        didSet {
            contentView.backgroundColor = .clear

            self.view.addSubview(contentView)
            contentView
                    .fix(top: (0, self.view), bottom: (0, self.view), toSafeArea: true)
                    .fix(leading: (0, self.view), trailing: (0, self.view))
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

    deinit {
        self.removeKeyboardListeners()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
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

extension NINQuestionnaireViewController: QuestionnaireConversationController {
    func updateConversationContentView(_ interval: TimeInterval = 0.0) {
        let newSection = self.prepareSection()
        self.addLoadingRow(at: newSection)
        self.scrollToBottom(at: newSection)     /// Scroll to bottom

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.removeLoadingRow(at: newSection)
            self.contentView.beginUpdates()     // Start loading questionnaires
            self.addQuestionnaireRows(at: newSection)
            self.addNavigationRow(at: newSection)
            self.contentView.endUpdates()       // Finish loading questionnaires

            self.scrollToBottom(at: newSection) /// Scroll to bottom
        }
    }
    func initiateConversationContentView(_ interval: TimeInterval) {
        self.contentView = self.generateTableView(isHidden: false)
        self.updateConversationContentView(interval)
    }

    private func scrollToBottom(at section: Int) {
        self.contentView.scrollToRow(at: IndexPath(row: self.contentView.numberOfRows(inSection: section)-1, section: section), at: .bottom, animated: true)
    }

    private func prepareSection() -> Int {
        guard let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        let section = conversationDataSource.insertSection()
        self.contentView.insertSections(IndexSet(integer: section), with: .left)

        return section
    }

    private func addLoadingRow(at section: Int) {
        guard var conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        conversationDataSource.isLoadingNewElements = true
        self.contentView.insertRows(at: [IndexPath(row: 0, section: section)], with: .left)
    }

    private func removeLoadingRow(at section: Int) {
        guard var conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("Not conformed") }
        conversationDataSource.isLoadingNewElements = false
        self.contentView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .right)
    }

    private func addQuestionnaireRows(at section: Int) {
        guard let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        do {
            let elements = try self.viewModel.getElements()
            elements.forEach { element in
                self.contentView.insertRows(at: [IndexPath(row: elements.firstIndex(where: { $0 == element })!, section: section)], with: .left)
                _ = conversationDataSource.insertRow()
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func addNavigationRow(at section: Int) {
        guard let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        do {
            _ = conversationDataSource.insertRow()
            let elements = try self.viewModel.getElements()
            self.contentView.insertRows(at: [IndexPath(row: elements.count, section: section)], with: .left)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func removeQuestionnaireSection() {
        guard let conversationDataSource = self.dataSourceDelegate as? QuestionnaireConversationHelpers else { fatalError("`dataSourceDelegate` does is conformed to `QuestionnaireConversationHelpers`") }
        self.contentView.deleteSections(IndexSet(integer: conversationDataSource.removeSection()), with: .right)
    }

}

extension NINQuestionnaireViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        self.dataSourceDelegate.numberOfPages()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        self.dataSourceDelegate.height(at: indexPath)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.dataSourceDelegate.numberOfMessages(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.dataSourceDelegate.cell(at: indexPath, view: self.contentView)
    }
}
