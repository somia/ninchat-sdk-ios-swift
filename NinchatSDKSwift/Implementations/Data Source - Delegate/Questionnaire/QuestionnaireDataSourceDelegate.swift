//
// Copyright (c) 15.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/** Delegate for the questionnaire view. */
protocol QuestionnaireDelegate {
    var onUpdateCellContent: (() -> Void)? { get set }
    var onRemoveCellContent: (() -> Void)? { get set }

    var isLoadingNewElements: Bool! { get set }
}

/** Data source for the questionnaire view. */
protocol QuestionnaireDataSource {
    /** How many pages are available. */
    func numberOfPages() -> Int

    /** How many element pages are available. */
    func numberOfMessages(in page: Int) -> Int

    /** Returns the height for each element at given index. */
    func height(at index: IndexPath) -> CGFloat

    /** Returns the cell with element embedded into it at given index. */
    mutating func cell(at index: IndexPath, view: UITableView) -> UITableViewCell

    var session: NINChatSession! { get }
    var viewModel: NINQuestionnaireViewModel! { get set }
    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession)
}

protocol QuestionnaireDataSourceDelegate: QuestionnaireDataSource, QuestionnaireDelegate {}

extension QuestionnaireDataSourceDelegate {
    internal func layoutSubview(_ view: UIView, parent: UIView) {
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
}
