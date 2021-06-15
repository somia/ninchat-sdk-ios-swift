//
// Copyright (c) 2.6.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import SwiftUI

struct Titlebar: View {
    private let VIEW_WIDTH: CGFloat  = 40.0
    private let VIEW_HEIGHT: CGFloat = 40.0
    private let VIEW_TITLE_WIDTH: CGFloat   = 122.0
    private let VIEW_TITLE_HEIGHT: CGFloat  = 15.0
    private let VIEW_TITLE_PLACEHOLDER_CORNER_RADIUS: CGFloat = 20.0
    private let VIEW_CLOSE_WIDTH: CGFloat   = 96.0
    private let VIEW_CLOSE_ICON_WIDTH: CGFloat  = 12.0
    private let VIEW_CLOSE_ICON_HEIGHT: CGFloat = 12.0
    private let VIEW_CLOSE_CORNER_RADIUS: CGFloat = 23.0
    private let VIEW_PADDING: CGFloat = 16.0
    private let VIEW_TITLE_PADDING: CGFloat = 4.0
    private let VIEW_TITLE_SPACING: CGFloat = 2.0
    private let VIEW_EMPTY_CLOSE_PADDING: CGFloat = 13.5
    
    private let session: NINChatSessionManager?
    private let avatar, name, job: String?
    private let defaultAvatar: UIImage?
    private var loader: ImageRemoteLoader?


    var onCloseTapped: (() -> Void)!
    init(_ session: NINChatSessionManager?,  avatar: String?, defaultAvatar: UIImage?, name: String?, job: String?) {
        self.session = session
        self.avatar = avatar
        self.defaultAvatar = defaultAvatar
        self.name = name
        self.job = job
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                HStack {
                    titlebarAvatar
                        .frame(width: VIEW_WIDTH, height: VIEW_HEIGHT)
                    titlebarName
                        .padding(VIEW_TITLE_PADDING)
                }
                Spacer()
                Button(action: { self.onCloseTapped() }) {
                    closeTitlebar
                            .background(close_background_color)
                }
                .frame(height: VIEW_HEIGHT)
                .cornerRadius(VIEW_CLOSE_CORNER_RADIUS)
                .overlay(RoundedRectangle(cornerRadius: VIEW_CLOSE_CORNER_RADIUS).stroke(close_border_color, lineWidth: close_border_width))
            }
            .background(view_background_color)
            .padding([.leading, .trailing], VIEW_PADDING)
        }
    }
}

// MARK: - Helper builders

extension Titlebar {
    @ViewBuilder
    var titlebarName: some View {
        if let name = self.name, !name.isEmpty {
            /// show titlebar
            VStack(alignment: .leading, spacing: VIEW_TITLE_SPACING) {
                Text(name)
                    .fontWeight(.semibold)
                    .foregroundColor(title_color)
                
                if let job = self.job, !job.isEmpty {
                    Text(job)
                        .foregroundColor(title_color)
                }
            }
        } else {
            /// show placeholder
            Rectangle()
                .fill(placeholder_color)
                .cornerRadius(5.0)
                .frame(width: VIEW_TITLE_WIDTH, height: VIEW_TITLE_HEIGHT)
        }
    }
    
    @ViewBuilder
    var titlebarAvatar: some View {
        /// show placeholder if the name is nill
        /// regardless of the avatar
        if self.name?.isEmpty ?? true {
            Rectangle()
                .fill(placeholder_color)
                .cornerRadius(VIEW_TITLE_PLACEHOLDER_CORNER_RADIUS)
        } else if let avatar = self.avatar, !avatar.isEmpty {
            /// don't show avatar is config.agentAvatar = false
            if let agentAvatar = self.session?.siteConfiguration.agentAvatar as? Bool, !agentAvatar {
                Group {}
            }
            
            RemoteImage(from: avatar, delegate: self.session?.delegate)
                .frame(width: VIEW_WIDTH, height: VIEW_HEIGHT)
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
        } else if let defaultAvatar = self.defaultAvatar {
            Image(uiImage: defaultAvatar)
                .resizable()
                .frame(width: VIEW_WIDTH, height: VIEW_HEIGHT)
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    var closeTitlebar: some View {
        if let closeTitle = self.session?.translate(key: Constants.kCloseText.rawValue, formatParams: [:]), !closeTitle.isEmpty {
            HStack {
                Spacer()
                Text(closeTitle)
                    .foregroundColor(close_title_color)
                    .font(.ninchat)
                Spacer()
                closeIcon
            }
            .frame(width: VIEW_CLOSE_WIDTH)
            .padding()
        } else {
            closeIcon
                .padding(VIEW_EMPTY_CLOSE_PADDING)
        }
    }

    @ViewBuilder
    var closeIcon: some View {
        Image(uiImage: self.close_icon)
            .resizable()
            .foregroundColor(close_title_color)
            .frame(width: VIEW_CLOSE_ICON_WIDTH, height: VIEW_CLOSE_ICON_HEIGHT, alignment: .center)
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - Overriders

extension Titlebar {
    var view_background_color: Color {
        if let layer = self.session?.delegate?.override(layerAsset: .ninchatModalTop), let color = layer.backgroundColor {
            return Color(UIColor(cgColor: color))
        }
        return .clear
    }
    
    var title_color: Color {
        if let color = self.session?.delegate?.override(colorAsset: .ninchatColorModalTitleText) {
            return Color(color)
        }
        return Color(.tTitleBlack)
    }
    
    var placeholder_color: Color {
        if let color = self.session?.delegate?.override(colorAsset: .ninchatColorTitlebarPlaceholder) {
            return Color(color)
        }
        return Color(.tPlaceholderGray)
    }
    
    var close_title_color: Color {
        if let color = self.session?.delegate?.override(colorAsset: .ninchatColorButtonCloseChatText) {
            return Color(color)
        } else if let color = self.session?.delegate?.override(colorAsset: .ninchatColorButtonSecondaryText) {
            return Color(color)
        }
        return Color(.blueButton)
    }
    
    var close_background_color: Color {
        if let layer = self.session?.delegate?.override(layerAsset: .ninchatChatCloseButton), let color = layer.backgroundColor {
            return Color(UIColor(cgColor: color))
        }
        return .white
    }
    
    var close_border_color: Color {
        if let layer = self.session?.delegate?.override(layerAsset: .ninchatChatCloseButton), let color = layer.borderColor {
            return Color(UIColor(cgColor: color))
        }
        return close_title_color
    }
    
    var close_border_width: CGFloat {
        if let layer = self.session?.delegate?.override(layerAsset: .ninchatChatCloseButton) {
            return layer.borderWidth
        }
        return 1.0
    }
    
    var close_icon: UIImage {
        UIImage(named: "icon_close_x", in: .SDKBundle, with: nil)!
    }
}

struct Titlebar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Titlebar(nil, avatar: nil, defaultAvatar: nil, name: "Agent", job: "developer")
                .previewLayout(.sizeThatFits)
            Titlebar(nil, avatar: nil, defaultAvatar: nil, name: "Agent", job: nil)
                .previewLayout(.sizeThatFits)
            Titlebar(nil, avatar: "https://avatars.githubusercontent.com/u/11143939?v=4", defaultAvatar: nil, name: "Agent", job: nil)
                .previewLayout(.sizeThatFits)
            Titlebar(nil, avatar: nil, defaultAvatar: nil, name: "Agent", job: "developer")
                .previewLayout(.sizeThatFits)
            Titlebar(nil, avatar: nil, defaultAvatar: UIImage(named: "icon_avatar_mine", in: .SDKBundle, compatibleWith: nil), name: "Agent", job: "developer")
                .previewLayout(.sizeThatFits)
            Titlebar(nil, avatar: nil, defaultAvatar: UIImage(named: "icon_avatar_mine", in: .SDKBundle, compatibleWith: nil), name: nil, job: nil)
                .previewLayout(.sizeThatFits)
        }
    }
}
