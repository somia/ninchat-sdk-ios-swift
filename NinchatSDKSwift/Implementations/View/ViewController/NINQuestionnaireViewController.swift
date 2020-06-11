//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable
import NinchatLowLevelClient

final class NINQuestionnaireViewController: UIViewController, ViewController {

    // MARK: - ViewController

    var session: NINChatSession!
    var queue: Queue?

    // MARK: - Injected

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
        if parent.subviews.filter({ $0 is QuestionnaireElement }).count > 0 {
            parent.subviews.filter({ $0 is QuestionnaireElement }).forEach({ $0.removeFromSuperview() })
        }
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
            return (indexPath.row == (try self.viewModel.getElements()).count) ? navigation(tableView, cellForRowAt: indexPath) : questionnaire(tableView, cellForRowAt: indexPath)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        do {
            let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configuration = try self.viewModel.getConfiguration()
            cell.requirementsSatisfied = self.viewModel.requirementsSatisfied
            cell.overrideAssets(with: self.session)

            self.viewModel.requirementSatisfactionUpdater = { satisfied in
                cell.requirementSatisfactionUpdater?(satisfied)
            }
            cell.onNextButtonTapped = { [weak self] in
                guard let nextPage = self?.viewModel.goToNextPage() else { return }
                (nextPage) ? self?.updateContentView() : self?.viewModel.finishQuestionnaire(for: nil, autoApply: false)
            }
            cell.onBackButtonTapped = { [weak self] in
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
            element.overrideAssets(with: self.session)

            if var view = element as? QuestionnaireSettable {
                view.presetAnswer = self.viewModel.getAnswersForElement(element)
            }
            if var view = element as? QuestionnaireOptionSelectableElement {
                view.onElementOptionSelected = { [weak self] option in
                    func showTargetPage(_ page: Int) {
                        guard (self?.viewModel.canGoToPage(page) ?? false), !(self?.viewModel.shouldWaitForNextButton ?? false) else { return }
                        if self?.viewModel.goToPage(page) ?? false {
                            view.deselect(option: option)
                            self?.updateContentView()
                        }
                    }

                    self?.viewModel.submitAnswer(key: element, value: option.value)
                    if let page = self?.viewModel.redirectTargetPage(for: option.value) {
                        showTargetPage(page)
                    } else if let page = self?.viewModel.logicTargetPage(key: element.elementConfiguration?.name ?? "", value: option.value) {
                        showTargetPage(page)
                    }
                }
                view.onElementOptionDeselected = { _ in
                    self.viewModel.removeAnswer(key: element)
                }
            }
            if var view = element as? QuestionnaireFocusableElement {
                view.onElementFocused = { _ in }
                view.onElementDismissed = { [weak self] element in
                    if let textView = element as? QuestionnaireElementTextArea, let text = textView.view.text, !text.isEmpty, textView.isCompleted {
                        self?.viewModel.submitAnswer(key: element, value: textView.view.text)
                    } else if let textField = element as? QuestionnaireElementTextField, let text = textField.view.text, !text.isEmpty, textField.isCompleted {
                        self?.viewModel.submitAnswer(key: element, value: textField.view.text)
                    } else {
                        self?.viewModel.removeAnswer(key: element)
                    }
                }
            }
            self.layoutSubview(element, parent: cell.content)

            return cell
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
