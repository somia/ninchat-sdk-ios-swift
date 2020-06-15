//
// Copyright (c) 15.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

/** Delegate for the questionnaire view. */
protocol QuestionnaireDelegate {
    var onUpdateCellContent: (() -> Void)? { get set }
}

/** Data source for the questionnaire view. */
protocol QuestionnaireDataSource {
    /** How many element pages there are. */
    func numberOfMessages() -> Int

    /** Returns the height for each element at given index. */
    func height(at index: IndexPath) -> CGFloat

    /** Returns the cell with element embedded into it at given index. */
    func cell(at index: IndexPath, view: UITableView) -> UITableViewCell

    init(viewModel: NINQuestionnaireViewModel, session: NINChatSession)
}

protocol QuestionnaireDataSourceDelegate: QuestionnaireDataSource, QuestionnaireDelegate {}
