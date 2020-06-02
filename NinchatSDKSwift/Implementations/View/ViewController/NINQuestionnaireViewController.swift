//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable
import NinchatLowLevelClient

final class NINQuestionnaireViewController: UIViewController, ViewController {

    private lazy var connector: QuestionnaireElementConnector = {
        var connector = QuestionnaireElementConnectorImpl(configurations: self.session.sessionManager.siteConfiguration.preAudienceQuestionnaire!)
        connector.logicContainsTags = { [weak self] logic in
            self?.viewModel.submitTags(logic?.tags! ?? [])
        }
        connector.onCompleteTargetReached = { [unowned self] logic in
            let queue: (canJoin: Bool, target: Queue?) = self.viewModel.canJoinGivenQueue(withID: logic?.queue ?? self.queue.queueID)
            if !queue.canJoin {
                connector.onRegisterTargetReached?(logic); return
            }
            self.viewModel.finishQuestionnaire()
            self.completeQuestionnaire?(queue.target!)
        }
        connector.onRegisterTargetReached = { [unowned self] logic in
            self.viewModel.registerAudience(queueID: logic?.queue ?? self.queue.queueID) { error in
                if let error = error {
                    debugger("** ** SDK: error in registering audience: \(error)")
                    Toast.show(message: .error("Error is submitting the answers")) {
                        self.session.onDidEnd()
                    }
                } else {
                    self.session.onDidEnd()
                }
            }
        }

        return connector
    }()

    // MARK: - ViewController

    var session: NINChatSession!
    var queue: Queue!

    // MARK: - Injected

    var viewModel: NINQuestionnaireViewModel!
    var completeQuestionnaire: ((_ queue: Queue) -> Void)?

    // MARK: - SubViews

    private var contentView: UITableView! {
        didSet {
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

        self.addKeyboardListeners()
        self.initiateIndicatorView()
        self.initiateContentView(0.5) /// let elements be loaded for a few seconds
    }

    deinit {
        self.removeKeyboardListeners()
    }
}

extension NINQuestionnaireViewController {
    private func layoutSubview(_ view: UIView, parent: UIView) {
        parent.addSubview(view)

        view
            .fix(top: (0.0, parent), bottom: (0.0, parent))
            .fix(leading: (0.0, parent), trailing: (0.0, parent))
        view.leading?.priority = .required
        view.trailing?.priority = .required
    }

    private func updateContentView(_ interval: TimeInterval = 0.0) {
        self.loadingIndicator.startAnimating()
        contentView?.hide(true, andCompletion: { [weak self] in
            self?.contentView?.removeFromSuperview()
            self?.initiateContentView(interval)
        })
    }

    private func initiateContentView(_ interval: TimeInterval) {
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

    private func generateTableView(isHidden: Bool) -> UITableView {
        let view = UITableView(frame: .zero)
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

extension NINQuestionnaireViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        do {
            let elements = try self.viewModel.getElements()
            return (indexPath.row == elements.count) ? 65.0 : elements[indexPath.row].elementHeight
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        do {
            return try self.viewModel.getElements().count + 1
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        do {
            let elements = try self.viewModel.getElements()
            return (indexPath.row == elements.count) ? navigation(tableView, cellForRowAt: indexPath) : questionnaire(tableView, cellForRowAt: indexPath)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// Show navigation buttons
        do {
            let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configuration = try self.viewModel.getConfiguration()
            cell.onNextButtonTapped = { [weak self] questionnaire in
                if self?.viewModel.goToNextPage() ?? false {
                    self?.updateContentView()
                }
            }
            cell.onBackButtonTapped = { [weak self] questionnaire in
                if self?.viewModel.goToPreviousPage() ?? false {
                    self?.updateContentView()
                }
            }
            return cell
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func questionnaire(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        do {
            let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            let element = try self.viewModel.getElements()[indexPath.row]
            if var view = element as? QuestionnaireOptionSelectableElement {
                view.onElementOptionSelected = { [weak self] option in
                    func showTargetPage(_ page: Int) {
                        self?.viewModel.goToPage(page)
                        view.deselect(option: option)
                        self?.updateContentView()
                    }

                    self?.viewModel.submitAnswer(key: element, value: option.value)
                    if let configuration = try! self?.viewModel.getConfiguration(), let targetElement = self?.connector.findElementAndPageRedirect(for: option.value, in: configuration), let targetPage = targetElement.1 {
                        showTargetPage(targetPage)
                    } else if let targetElement = self?.connector.findElementAndPageLogic(for: [element.elementConfiguration?.name ?? "":AnyCodable(option.value)]), let targetPage = targetElement.1 {
                        showTargetPage(targetPage)
                    }
                }
                view.onElementOptionDeselected = { option in
                    self.viewModel.removeAnswer(key: element, value: option.value)
                }
            }
            if var view = element as? QuestionnaireFocusableElement {
                view.onElementFocused = { _ in }
                view.onElementDismissed = { [weak self] element in
                    if let textView = element as? QuestionnaireElementTextArea {
                        self?.viewModel.submitAnswer(key: element, value: textView.view.text)
                    } else if let textField = element as? QuestionnaireElementTextField {
                        self?.viewModel.submitAnswer(key: element, value: textField.view.text)
                    }
                }
            }
            element.overrideAssets(with: self.session, isPrimary: false)
            self.layoutSubview(element, parent: cell.content)

            return cell
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
