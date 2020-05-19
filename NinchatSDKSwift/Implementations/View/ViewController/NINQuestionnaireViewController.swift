//
// Copyright (c) 12.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

final class NINQuestionnaireViewController: UIViewController, ViewController {

    // MARK: - ViewController

    var session: NINChatSession!

    // MARK: - Outlets
/*
    @IBOutlet private(set) weak var ttl: QuestionnaireElementText! {
        didSet {
            ttl.delegate = self
        }
    }
    @IBOutlet private(set) weak var btn: QuestionnaireElementRadio! {
        didSet {
            btn.onElementFocused = { element in
                print(element.self)
            }
        }
    }
    @IBOutlet private(set) weak var checkbox: QuestionnaireElementCheckbox! {
        didSet {
            checkbox.tag = 0
            checkbox.onElementFocused = { element in
                print(element.self)
            }
        }
    }
    @IBOutlet private(set) weak var checkbox2: QuestionnaireElementCheckbox! {
        didSet {
            checkbox2.tag = 1
            checkbox2.onElementFocused = { element in
                print(element.self)
            }
        }
    }
    @IBOutlet private(set) weak var input: QuestionnaireElementTextField! {
        didSet {
            input.onElementFocused = { element in
                print("\(element.self) Focused")
            }
            input.onElementDismissed = { element in
                print("\(element.self) Dismissed")
            }
        }
    }
    @IBOutlet private(set) weak var inputArea: QuestionnaireElementTextArea! {
        didSet {
            inputArea.onElementFocused = { element in
                print("\(element.self) Focused")
            }
            inputArea.onElementDismissed = { element in
                print("\(element.self) Dismissed")
            }
        }
    }
    @IBOutlet private(set) weak var select: QuestionnaireElementSelect! {
        didSet {
            select.onElementFocused = { element in
                print(element.self)
            }
            select.onOptionSelected = { option in
                print("\(option.label): \(option.value)")
            }
        }
    }
    @IBOutlet private(set) weak var nextButton: QuestionnaireButton! {
        didSet {
            nextButton.type = .next
            nextButton.closure = { button in
                print("On next: \(button)")
            }
        }
    }
    @IBOutlet private(set) weak var backButton: QuestionnaireButton! {
        didSet {
            backButton.type = .back
            backButton.closure = { button in
                print("On back: \(button)")
            }
        }
    }
*/
    // MARK: - UIViewController life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
/*
        if let audienceQuestionnaire = session.sessionManager.siteConfiguration.preAudienceQuestionnaire {
            if let configuration = audienceQuestionnaire.first {
                nextButton.configuration = configuration
                backButton.configuration = configuration
            }
            if let configuration = audienceQuestionnaire.map({ $0.elements?.filter({ $0.element == .text }) }).first {
                ttl.configuration = configuration?[0]
            }
            if let configurations = audienceQuestionnaire.map({ $0.elements?.filter({ $0.element == .radio }) }).first {
                btn.configuration = configurations?[0]
                btn
                    .deactivate(constraints: [.width])
                    .fix(width: self.view.bounds.width - 16.0)
            }
            if let configurations = audienceQuestionnaire.map({ $0.elements?.filter({ $0.element == .checkbox }) }).first {
                checkbox.configuration = configurations?[0]
                checkbox2.configuration = configurations?[0]

                checkbox
                        .fix(leading: (16.0, self.view))
                checkbox2
                        .fix(leading: (16.0, self.view))
            }
            if let configurations = audienceQuestionnaire.map({ $0.elements?.filter({ $0.element == .input && $0.type == .text }) }).first {
                input.configuration = configurations?[0]
            }
            if let configurations = audienceQuestionnaire.map({ $0.elements?.filter({ $0.element == .textarea }) }).first {
                inputArea.configuration = configurations?[0]
            }
            if let configurations = audienceQuestionnaire.map({ $0.elements?.filter({ $0.element == .select }) }).first {
                select.configuration = configurations?[0]
            }
        }
        self.overrideAssets()
 */
    }
}

extension NINQuestionnaireViewController {
    /*
    private func overrideAssets() {
        btn.overrideAssets(with: self.session)
        checkbox.overrideAssets(with: self.session)
        checkbox2.overrideAssets(with: self.session)
        input.overrideAssets(with: self.session)
        inputArea.overrideAssets(with: self.session)
        select.overrideAssets(with: self.session)
    }
 */
}
