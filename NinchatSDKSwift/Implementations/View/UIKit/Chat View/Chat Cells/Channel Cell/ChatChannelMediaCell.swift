//
// Copyright (c) 29.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ChannelMediaCellDelegate {
    func didLoadAttachment(_ image: UIImage?)
}

protocol ChannelMediaCell {
    var cachedImage: [String:UIImage]? { get }
    var originalImage: [String:UIImage]? { set get }

    /// Outlets
    var parentView: UIView! { get set }
    var messageImageViewContainer: UIView! { get set }
    var messageImageView: UIImageView! { get set }
    var videoPlayIndicator: UIImageView! { get set }

    func populateText(message: TextMessage, attachment: FileInfo?)
}

extension ChannelMediaCell where Self:ChatChannelCell {
    func populateText(message: TextMessage, attachment: FileInfo?) {
        /// setup the aspect ratio doesn't need to be done async
        guard let message = message as? TextMessage, let attachment = message.attachment else { return }
        self.set(aspect: attachment.aspectRatio, message.series)

        /// early return to avoid rendering performance issues.
        if !attachment.fileExpired {
            try? self.updateAttachment(asynchronous: self.messageImageView.height == nil, fromCache: true);
            return
        }

        /// attachment needs to be updated, it was probably expired
        attachment.updateInfo(session: self.session) { [weak self] error, didRefreshNetwork in
            guard error == nil else { return }
            do {
                try self?.updateAttachment(asynchronous: didRefreshNetwork || self?.messageImageView.height == nil, fromCache: false)
            } catch {
                debugger("Error in updating attachment info: \(error)")
            }
        }
    }

    func updateAttachment(asynchronous: Bool, fromCache: Bool) throws {
        guard let message = self.message as? TextMessage else { throw NINUIExceptions.noMessage }
        guard let attachment = message.attachment else { throw NINUIExceptions.noAttachment }
        guard attachment.isVideo || attachment.isImage else { throw NINUIExceptions.invalidAttachment }

        /// Make sure we have an image tap recognizer in place
        self.resetImageLayout()
        if attachment.isImage {
            self.videoPlayIndicator.isHidden = true
            self.messageImageView.contentMode = .scaleAspectFill
            self.updateImage(from: attachment, thumbnailUrl: attachment.thumbnailUrl, imageURL: attachment.url, fromCache, asynchronous, message.series)
        } else if attachment.isVideo, let videoURL = attachment.url {
            self.videoPlayIndicator.isHidden = false
            self.messageImageView.contentMode = .scaleAspectFill
            try self.updateVideo(from: attachment, videoURL: videoURL, asynchronous, message.series)
        }
    }

    /// Update constraints to match new thumbnail image size
    private func updateVideo(from attachment: FileInfo, videoURL: String, _ asynchronous: Bool, _ isSeries: Bool) throws {
        guard let thumbnailManager = self.videoThumbnailManager else { throw NINUIExceptions.noThumbnailManager }

        /// For video we must fetch the thumbnail image
        thumbnailManager.fetchVideoThumbnail(fromURL: videoURL) { [weak self, message = message] error, fromCache, thumbnail in
            if error != nil { Toast.show(message: .error("Failed to get video thumbnail")); return }
            self?.updateMessageImageView(attachment: attachment, thumbnailUrl: nil, imageURL: nil, image: thumbnail, asynchronous: asynchronous, isSeries: isSeries)
        }
    }

    /// asynchronous = YES implies we're calling this asynchronously from the
    /// `updateInfo(session:completion:)` completion block (meaning it did a network update)
    private func updateImage(from attachment: FileInfo, thumbnailUrl: String?, imageURL: String?, _ fromCache: Bool, _ asynchronous: Bool, _ isSeries: Bool) {
        if fromCache, let id = self.message?.messageID, let image = self.cachedImage?[id] {
            self.updateMessageImageView(attachment: attachment, thumbnailUrl: nil, imageURL: nil, image: image, asynchronous: asynchronous, isSeries: isSeries); return
        }
        self.updateMessageImageView(attachment: attachment, thumbnailUrl: thumbnailUrl, imageURL: imageURL, image: nil, asynchronous: asynchronous, isSeries: isSeries)
    }

    private func updateMessageImageView(attachment: FileInfo, thumbnailUrl: String?, imageURL: String?, image: UIImage?, asynchronous: Bool, isSeries: Bool) {
        DispatchQueue.main.async {
            if let image = image {
                self.messageImageView.image = image
                (self as? ChannelMediaCellDelegate)?.didLoadAttachment(image)
            }
            /// Load the image from cache first
            else if let id = self.message?.messageID, let image = self.cachedImage?[id] {
                self.messageImageView.image = image
            }
            /// Load the thumbnail image in message image view over HTTP or from local cache
            else if let thumbnailUrl = thumbnailUrl {
                self.messageImageView.fetchImage(from: URL(string: thumbnailUrl)) { [weak self, message = self.message] data in
                    DispatchQueue.main.async {
                        if self?.message?.messageID != message?.messageID { debugger("** ** Dismiss unrelated attachment"); return }
                        self?.messageImageView.image = UIImage(data: data)

                        (self as? ChannelMediaCellDelegate)?.didLoadAttachment(UIImage(data: data))
                    }
                }
            }
        }

        /// Load the image in message image view over HTTP in the background for later uses
        if let messageID = self.message?.messageID, self.originalImage?[messageID] == nil, let imageURL = imageURL, image == nil {
            DispatchQueue.global(qos: .background).async {
                imageURL.fetchImage { [weak self, messageID] data in
                    self?.originalImage?[messageID] = UIImage(data: data)
                }
            }
        }
    }

    private func set(aspect ratio: Double?, _ isSeries: Bool) {
        guard let ratio = ratio, self.contentView.frame.width > 0 else { return }
        let width: CGFloat = min(self.contentView.bounds.width, 400) / 2, height: CGFloat = width / CGFloat(ratio)
        debugger("attachment constraints: width: \(width), height: \(height)")

        self.parentView.fix(height: max(height, 150.0))
        self.messageImageView.fix(width: width)
        self.messageImageViewContainer.top?.constant = (isSeries) ? 16 : 8
    }

    private func resetImageLayout() {
        self.messageImageView.image = nil
        self.messageImageViewContainer.gestureRecognizers?.forEach { self.messageImageViewContainer.removeGestureRecognizer($0) }
    }
}

final class ChatChannelMediaMineCell: ChatChannelMineCell, ChannelMediaCell, ChannelMediaCellDelegate {
    var cachedImage: [String:UIImage]? = [:]
    var originalImage: [String:UIImage]? = [:]
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var messageImageViewContainer: UIView! {
        didSet {
            messageImageViewContainer.round(radius: 10.0)
        }
    }
    @IBOutlet weak var messageImageView: UIImageView! {
        didSet {
            messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
            messageImageView.contentMode = .scaleToFill
        }
    }
    @IBOutlet weak var videoPlayIndicator: UIImageView! {
        didSet {
            videoPlayIndicator.tintColor = .white
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        if let id = self.message?.messageID, let image = cachedImage?[id] {
            self.messageImageView.image = image
        } else {
            self.messageImageView.image = nil
        }
        self.videoPlayIndicator.isHidden = true
        self.layoutIfNeeded()
    }

    @objc
    func didTappedOnImage() {
        guard let message = self.message as? TextMessage, let attachment = message.attachment else { return }

        if attachment.isVideo {
            /// Will open video player
            self.onImageTapped?(attachment, nil)
        } else if attachment.isImage, let image = self.originalImage?[message.messageID] {
            /// Will show full-screen image viewer
            self.onImageTapped?(attachment, image)
        }
    }

    // MARK: - ChannelMediaCellDelegate
    func didLoadAttachment(_ image: UIImage?) {
        if let image = image, let id = self.message?.messageID {
            self.cachedImage?[id] = image
        }
    }
}

final class ChatChannelMediaOthersCell: ChatChannelOthersCell, ChannelMediaCell, ChannelMediaCellDelegate {
    var cachedImage: [String:UIImage]? = [:]
    var originalImage: [String:UIImage]? = [:]
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var messageImageViewContainer: UIView! {
        didSet {
            messageImageViewContainer.round(radius: 10.0)
        }
    }
    @IBOutlet weak var messageImageView: UIImageView! {
        didSet {
            messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
            messageImageView.contentMode = .scaleToFill
        }
    }
    @IBOutlet weak var videoPlayIndicator: UIImageView! {
        didSet {
            videoPlayIndicator.tintColor = .white
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        if let id = self.message?.messageID, let image = cachedImage?[id] {
            self.messageImageView.image = image
        } else {
            self.messageImageView.image = nil
        }
        self.videoPlayIndicator.isHidden = true
        self.layoutIfNeeded()
    }

    @objc
    func didTappedOnImage() {
        guard let message = self.message as? TextMessage, let attachment = message.attachment else { return }

        if attachment.isVideo {
            /// Will open video player
            self.onImageTapped?(attachment, nil)
        } else if attachment.isImage, let image = self.originalImage?[message.messageID] {
            /// Will show full-screen image viewer
            self.onImageTapped?(attachment, image)
        }
    }

    // MARK: - ChannelMediaCellDelegate
    func didLoadAttachment(_ image: UIImage?) {
        if let image = image, let id = self.message?.messageID {
            self.cachedImage?[id] = image
        }
    }
}
