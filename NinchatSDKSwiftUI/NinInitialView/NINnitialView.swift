//
// Copyright (c) 26.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Combine
import SwiftUI

struct NINInitialView: View {
    private let viewModel: NINInitialViewModel
    
    // MARK: - Overrides
    private let titleOverride, infoOverride: Override?
    private let topViewOverride, bottomViewOverride: Override?
    private let primaryButtonOverride, secondaryButtonOverride: Override?
    
    let titleHeight: CGFloat = 70.0
    let buttonHeight: CGFloat = 60.0
    let buttonSpace: CGFloat = 1.0
    let bottomHeight: CGFloat = 50.0
    let noQueueTextHeight: CGFloat = 70.0
    var topViewHeight: CGFloat {
        CGFloat(viewModel.queues.count + 1)
            * (buttonHeight + buttonSpace)
            + bottomHeight
            + ((viewModel.queues.count == 0) ? noQueueTextHeight : 0)
    }
    let modHieght: CGFloat = 50.0
    
    init(viewModel: NINInitialViewModel, delegate: NinchatSwiftUIInternalDelegate?) {
        self.viewModel = viewModel
        self.titleOverride = delegate?.overrideView(.ninchatWelcomeText)
        self.infoOverride = delegate?.overrideView(.ninchatInfoText)
        self.topViewOverride = delegate?.overrideView(.ninchatBackgroundTop)
        self.bottomViewOverride = delegate?.overrideView(.ninchatBackgroundBottom)
        self.primaryButtonOverride = delegate?.overrideView(.ninchatPrimaryButton)
        self.secondaryButtonOverride = delegate?.overrideView(.ninchatSecondaryButton)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                VStack {
                    Spacer()
                    NINAttributedText(viewModel.title, alignment: .center, override: titleOverride)
                }
                .frame(maxHeight: titleHeight)
                
                ZStack {
                    GeometryReader { geo in
                        HStack {
                            Spacer()
                            VStack {
                                queueStack(size: CGSize(width: geo.size.width, height: buttonHeight))
                                NINSecondaryButtonView(viewModel.cancel, size: CGSize(width: geo.size.width*3/5, height: buttonHeight), override: secondaryButtonOverride) {
                                    viewModel.onCancelTapped?()
                                }
                                Spacer(minLength: buttonSpace)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(maxHeight: topViewHeight)
            }
            .background((topViewOverride as? NinchatSwiftUIViewOverridingOptions)?.backgroundColor?.0 ?? .white)
            
            ZStack(alignment: .topLeading) {
                Color((bottomViewOverride as? NinchatSwiftUIViewOverridingOptions)?.backgroundColor?.1 ?? .initialBottomDefaultBackground)
                ZStack {
                    NINAttributedText(viewModel.motd, override: infoOverride)
                }
                .padding()
            }
        }
        .navigationBarTitle("")     // trick in SwiftUI: to hide the navigation bar
        .navigationBarHidden(true)
    }
}

// MARK: - Draw Queues

extension NINInitialView {
    @ViewBuilder
    func queueStack(size: CGSize) -> some View {
        if viewModel.queues.count == 0 {
            Spacer(minLength: buttonSpace)
            ZStack {
                NINAttributedText(viewModel.noQueueText, alignment: .center, override: nil)
            }
            .frame(width: size.width, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .frame(maxHeight: topViewHeight/2)
        } else {
            ForEach(viewModel.queuesTitles, id: \.self) { title in
                Spacer(minLength: buttonSpace)
                VStack {
                    NINPrimaryButtonView(title, size: CGSize(width: size.width*3/5, height: size.height), override: primaryButtonOverride) {
                        viewModel.onQueueTapped(title)
                    }
                }
            }
            Spacer(minLength: buttonSpace)
        }
    }
}

