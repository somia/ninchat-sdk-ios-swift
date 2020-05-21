//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQuestionnaireViewController: UIViewController, ViewController {

    private var elements: [QuestionnaireElement] {
        if let audienceQuestionnaire = session.sessionManager.siteConfiguration.preAudienceQuestionnaire {
            let views = QuestionnaireElementConverter(configurations: audienceQuestionnaire).elements
            guard views.count > self.pageNumber else { fatalError("Invalid number of questionnaires") }

            return views[self.pageNumber]
        }
        return []
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

    // MARK: - UIViewController life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

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
        self.elements[indexPath.row].height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        elements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QuestionnaireCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let view = self.elements[indexPath.row]
        view.overrideAssets(with: self.session, isPrimary: false)
        (view as? QuestionnaireElementWithNavigationButtons)?.onNextButtonTapped = { [weak self] questionnaire in
            self?.pageNumber += 1
            self?.updateLayout()
        }
        (view as? QuestionnaireElementWithNavigationButtons)?.onBackButtonTapped = { [weak self] questionnaire in
            self?.pageNumber -= 1
            self?.updateLayout()
        }
        self.layoutSubview(view, parent: cell.content)

        return cell
    }
}
