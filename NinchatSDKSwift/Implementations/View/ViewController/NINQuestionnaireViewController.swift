//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import AnyCodable
import NinchatLowLevelClient

final class NINQuestionnaireViewController: UIViewController, ViewController {

    private lazy var views: [[QuestionnaireElement]] = {
        QuestionnaireElementConverter(configurations: self.session.sessionManager.siteConfiguration.preAudienceQuestionnaire!).elements
    }()
    private lazy var connector: QuestionnaireElementConnector = {
        var connector = QuestionnaireElementConnectorImpl(configurations: self.session.sessionManager.siteConfiguration.preAudienceQuestionnaire!)
        connector.onCompleteTargetReached = { [unowned self] logic in
            self.completeQuestionnaire?(NINLowLevelClientProps.initiate(metadata: self.answers))
        }
        connector.onRegisterTargetReached = { [unowned self] logic in
            self.registerQuestionnaire?(NINLowLevelClientProps.initiate(metadata: self.answers))
        }

        return connector
    }()
    private var configuration: QuestionnaireConfiguration {
        if let audienceQuestionnaire = session.sessionManager.siteConfiguration.preAudienceQuestionnaire?.filter({ $0.element != nil || $0.elements != nil }) {
            guard audienceQuestionnaire.count > self.pageNumber else { fatalError("Invalid number of questionnaires configurations") }

            return audienceQuestionnaire[self.pageNumber]
        }
        fatalError("Configuration for the page number: \(self.pageNumber) is not exits")
    }
    private var elements: [QuestionnaireElement] {
        guard self.views.count > self.pageNumber else { fatalError("Invalid number of questionnaires views") }
        return self.views[self.pageNumber]
    }
    private var previousPage: Int!
    private var answers: [String:AnyCodable] = [:]

    // MARK: - ViewController

    var session: NINChatSession!

    // MARK: - Injected

    var pageNumber: Int!
    var registerQuestionnaire: ((_ answers: NINLowLevelClientProps) -> Void)?
    var completeQuestionnaire: ((_ answers: NINLowLevelClientProps) -> Void)?

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

        self.previousPage = self.pageNumber
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
        if indexPath.row == self.elements.count {
            return 65.0
        }
        return self.elements[indexPath.row].elementHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.elements.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == self.elements.count {
            return navigation(tableView, cellForRowAt: indexPath)
        }
        return questionnaire(tableView, cellForRowAt: indexPath)
    }

    private func navigation(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// Show navigation buttons
        let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.configuration = self.configuration
        cell.onNextButtonTapped = { [weak self] questionnaire in
            if (self?.views.count ?? 0) > (self?.pageNumber ?? 0) + 1 {
                self?.previousPage = self?.pageNumber
                self?.pageNumber += 1
                self?.updateContentView()
            }
        }
        cell.onBackButtonTapped = { [weak self] questionnaire in
            if (self?.pageNumber ?? 0) > 0 {
                self?.pageNumber = self?.previousPage
                self?.updateContentView()
            }
        }
        return cell
    }

    private func questionnaire(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let element = self.elements[indexPath.row]
        if var view = element as? QuestionnaireOptionSelectableElement {
            func submitAnswer(key: String, value: AnyCodable) {
                self.answers[key] = value
            }
            func removeAnswer(key: String, value: AnyCodable) {
                if let answer = self.answers[key], answer == value {
                    self.answers.removeValue(forKey: key)
                }
            }

            view.onElementOptionSelected = { [weak self] option in
                func showTargetPage(_ page: Int) {
                    self?.previousPage = self?.pageNumber
                    self?.pageNumber = page
                    view.deselect(option: option)
                    self?.updateContentView()
                }

                guard let elementConfiguration = element.elementConfiguration else { return }
                if let configuration = self?.configuration,
                   let targetElement = self?.connector.findElementAndPageRedirect(for: option.value, in: configuration), let targetPage = targetElement.1 {
                    showTargetPage(targetPage)
                } else if let targetElement = self?.connector.findElementAndPageLogic(for: [elementConfiguration.name:AnyCodable(option.value)]), let targetPage = targetElement.1 {
                    showTargetPage(targetPage)
                }
                submitAnswer(key: elementConfiguration.name, value: AnyCodable(option.value))
            }
            view.onElementOptionDeselected = { option in
                if let configuration = element.elementConfiguration {
                    removeAnswer(key: configuration.name, value: AnyCodable(option.value))
                }
            }
        }
        if var view = element as? QuestionnaireFocusableElement {
            view.onElementFocused = { questionnaire in }
            view.onElementDismissed = { option in }
        }
        element.overrideAssets(with: self.session, isPrimary: false)
        self.layoutSubview(element, parent: cell.content)

        return cell
    }
}
