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

    // MARK: - Injected

    var queue: Queue?
    var dataSourceDelegate: QuestionnaireDataSourceDelegate! {
        didSet {
            dataSourceDelegate.onUpdateCellContent = { [weak self] in
                self?.updateContentView()
            }
        }
    }
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
            contentView.backgroundColor = .clear

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

        self.overrideAssets()
        self.addKeyboardListeners()
        self.initiateIndicatorView()
        self.initiateContentView(0.5) /// let elements be loaded for a few seconds
    }

    deinit {
        self.removeKeyboardListeners()
    }

    private func overrideAssets() {
        if let backgroundImage = self.session.override(imageAsset: .questionnaireBackground) {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else if let bundleImage = UIImage(named: "chat_background_pattern", in: .SDKBundle, compatibleWith: nil) {
            self.view.backgroundColor = UIColor(patternImage: bundleImage)
        }
    }
}

extension NINQuestionnaireViewController {
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
        self.dataSourceDelegate.height(at: indexPath)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.dataSourceDelegate.numberOfMessages()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.dataSourceDelegate.cell(at: indexPath, view: self.contentView)
    }
}
