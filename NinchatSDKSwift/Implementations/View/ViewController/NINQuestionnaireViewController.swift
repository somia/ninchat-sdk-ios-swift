//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQuestionnaireViewController: UIViewController, ViewController {

    private lazy var views: [[QuestionnaireElement]] = {
        QuestionnaireElementConverter(configurations: self.session.sessionManager.siteConfiguration.preAudienceQuestionnaire!).elements
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

    // MARK: - ViewController

    var session: NINChatSession!

    // MARK: - Injected

    var pageNumber: Int!
    var finishQuestionnaire: (() -> Void)?

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
        self.initiateIndicatorView()
        self.initiateContentView(0.5) /// let elements be loaded for a few seconds
    }

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
}

extension NINQuestionnaireViewController {
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
            /// Show navigation buttons
            let cell: QuestionnaireNavigationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configuration = self.configuration
            cell.onNextButtonTapped = { [weak self] questionnaire in
                self?.pageNumber += 1
                self?.updateContentView()
            }
            cell.onBackButtonTapped = { [weak self] questionnaire in
                self?.pageNumber -= 1
                self?.updateContentView()
            }
            return cell
        }

        /// Show questionnaire items
        let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let view = self.elements[indexPath.row]
        view.overrideAssets(with: self.session, isPrimary: false)
        self.layoutSubview(view, parent: cell.content)

        return cell
    }
}
