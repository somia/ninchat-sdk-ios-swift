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

    // MARK: - Outlets

    @IBOutlet private(set) weak var contentView: UITableView! {
        didSet {
            contentView.separatorStyle = .none
            contentView.allowsSelection = false

            contentView.delegate = self
            contentView.dataSource = self
        }
    }

    // MARK: - UIViewController life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func layoutSubview(_ view: UIView, parent: UIView) {
        parent.addSubview(view)

        view
            .fix(top: (0.0, parent), bottom: (0.0, parent))
            .fix(leading: (0.0, parent), trailing: (0.0, parent))
        view.leading?.priority = .required
        view.trailing?.priority = .required
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
        let view = self.elements[indexPath.row]
        view.overrideAssets(with: self.session, isPrimary: false)

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_view")!
        self.layoutSubview(view, parent: cell.contentView)

        return cell
    }
}