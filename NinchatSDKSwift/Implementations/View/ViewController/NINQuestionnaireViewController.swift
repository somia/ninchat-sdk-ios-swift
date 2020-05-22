//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQuestionnaireViewController: UIViewController, ViewController {

    private var _configuration: QuestionnaireConfiguration {
        if let audienceQuestionnaire = session.sessionManager.siteConfiguration.preAudienceQuestionnaire {
            guard audienceQuestionnaire.count > self.pageNumber else { fatalError("Invalid number of questionnaires configurations") }

            return audienceQuestionnaire[self.pageNumber]
        }
        fatalError("Configuration for the page number: \(self.pageNumber ?? nil) is not exits")
    }
    private var _elements: [QuestionnaireElement] {
        if let audienceQuestionnaire = session.sessionManager.siteConfiguration.preAudienceQuestionnaire {
            let views = QuestionnaireElementConverter(configurations: audienceQuestionnaire).elements
            guard views.count > self.pageNumber else { fatalError("Invalid number of questionnaires views") }

            return views[self.pageNumber]
        }
        return []
    }
    private var configuration: QuestionnaireConfiguration!
    private var elements: [QuestionnaireElement] = []

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

    // MARK: - UIViewController life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        elements = _elements
        configuration = _configuration
        contentView = generateTableView(isHidden: false)
    }

    private func layoutSubview(_ view: UIView, parent: UIView) {
        parent.addSubview(view)

        view
            .fix(top: (0.0, parent), bottom: (0.0, parent))
            .fix(leading: (0.0, parent), trailing: (0.0, parent))
        view.leading?.priority = .required
        view.trailing?.priority = .required
    }

    private func updateLayout() {
        elements = _elements
        configuration = _configuration
        contentView?.hide(true, andCompletion: { [weak self] in
            DispatchQueue.main.async {
                self?.contentView?.removeFromSuperview()
                self?.contentView = self?.generateTableView(isHidden: true)
                self?.contentView?.hide(false)
            }
        })
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
        return self.elements[indexPath.row].height
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
                self?.updateLayout()
            }
            cell.onBackButtonTapped = { [weak self] questionnaire in
                self?.pageNumber -= 1
                self?.updateLayout()
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
