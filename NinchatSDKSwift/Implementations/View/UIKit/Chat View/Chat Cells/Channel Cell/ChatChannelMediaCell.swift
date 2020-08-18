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

    /// Outlets
    var messageImageViewContainer: UIView! { get set }
    var messageImageView: UIImageView! { get set }
    var videoPlayIndicator: UIImageView! { get set }
    
    func populateText(message: TextMessage, attachment: FileInfo?)
}

extension ChannelMediaCell where Self:ChatChannelCell {
    func populateText(message: TextMessage, attachment: FileInfo?) {
        attachment?.updateInfo(session: self.session) { [weak self] error, didRefreshNetwork in
            guard error == nil else { return }
            do {
                try self?.updateAttachment(asynchronous: didRefreshNetwork || self?.messageImageView.height == nil)
            } catch {
                debugger("Error in updating attachment info: \(error)")
            }
        }
    }
    
    func updateAttachment(asynchronous: Bool) throws {
        guard let message = self.message as? TextMessage else { throw NINUIExceptions.noMessage }
        guard let attachment = message.attachment else { throw NINUIExceptions.noAttachment }
        guard attachment.isVideo || attachment.isImage else { throw NINUIExceptions.invalidAttachment }
        
        /// Make sure we have an image tap recognizer in place
        self.resetImageLayout()
        
        if attachment.isImage, let imageURL = attachment.url {
            self.videoPlayIndicator.isHidden = true
            self.messageImageView.contentMode = .scaleAspectFit
            self.updateImage(from: attachment, imageURL: imageURL, asynchronous, message.series)
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
        thumbnailManager.fetchVideoThumbnail(fromURL: videoURL) { [weak self] error, fromCache, thumbnail in
            if error != nil { Toast.show(message: .error("Failed to get video thumbnail")); return }
            self?.updateMessageImageView(attachment: attachment, imageURL: nil, image: thumbnail, asynchronous: asynchronous, isSeries: isSeries)
        }
    }
    
    /// asynchronous = YES implies we're calling this asynchronously from the
    /// `updateInfo(session:completion:)` completion block (meaning it did a network update)
    private func updateImage(from attachment: FileInfo, imageURL: String, _ asynchronous: Bool, _ isSeries: Bool) {
        self.updateMessageImageView(attachment: attachment, imageURL: imageURL, image: nil, asynchronous: asynchronous, isSeries: isSeries)
    }

    private func updateMessageImageView(attachment: FileInfo, imageURL: String?, image: UIImage?, asynchronous: Bool, isSeries: Bool) {
        DispatchQueue.main.async {
            if let id = self.message?.messageID, let image = self.cachedImage?[id] {
                self.messageImageView.image = image
            }
            /// Load the image in message image view over HTTP or from local cache
            else if let imageURL = imageURL {
                let message = self.message
                self.messageImageView.fetchImage(from: URL(string: imageURL)) { [weak self, message] data in
                    if self?.message?.messageID != message?.messageID { debugger("** ** Dismiss unrelated attachment"); return }
                    self?.messageImageView.image = UIImage(data: data)
                    (self as? ChannelMediaCellDelegate)?.didLoadAttachment(UIImage(data: data))
                }
            } else if let image = image {
                self.messageImageView.image = image
                (self as? ChannelMediaCellDelegate)?.didLoadAttachment(image)
            }
            self.set(aspect: CGFloat(attachment.aspectRatio ?? 1), isSeries)

            guard !self.isReloading && asynchronous else { return }
            /// Inform the chat view that our cell might need resizing due to new constraints.
            /// We do this regardless of fromCache -value as this method may have been called asynchronously
            /// from `updateInfo(session:completion:)` completion block in populate method.
            self.onConstraintsUpdate?()
        }
    }
    
    private func set(aspect ratio: CGFloat, _ isSeries: Bool, update: Bool = false) {
        /// Return if the constraints are currently set
        if let _ = self.messageImageViewContainer.width { return }
        
        let width: CGFloat = (min(self.contentView.bounds.width, 400) / 3) * 2
        self.messageImageViewContainer.fix(width: width, height: width * (1/ratio))
        self.messageImageViewContainer.height?.priority = .defaultHigh
        self.messageImageViewContainer.width?.priority = .defaultHigh
        self.messageImageViewContainer.top?.constant = (isSeries) ? 16 : 8

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    private func resetImageLayout() {
        self.messageImageViewContainer.gestureRecognizers?.forEach { self.messageImageViewContainer.removeGestureRecognizer($0) }
    }
}

final class ChatChannelMediaMineCell: ChatChannelMineCell, ChannelMediaCell, ChannelMediaCellDelegate {
    var cachedImage: [String:UIImage]? = [:]
    @IBOutlet weak var messageImageViewContainer: UIView! {
        didSet {
            messageImageViewContainer.round(radius: 10.0)
        }
    }
    @IBOutlet weak var messageImageView: UIImageView! {
        didSet {
            messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
            messageImageView.contentMode = .scaleAspectFill
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
    }

    @objc
    func didTappedOnImage() {
        guard let message = self.message as? TextMessage, let attachment = message.attachment else { return }
        
        if attachment.isVideo {
            /// Will open video player
            self.onImageTapped?(attachment, nil)
        } else if attachment.isImage, let image = self.messageImageView.image {
            /// Will show full-screen image viewer
            self.onImageTapped?(attachment, image)
        }
    }

    // MARK: - ChannelMediaCellDelegate
    func didLoadAttachment(_ image: UIImage?) {
        if let image = image, self.cachedImage == nil {
            self.cachedImage?[self.message?.messageID ?? ""] = image
        }
    }
}

final class ChatChannelMediaOthersCell: ChatChannelOthersCell, ChannelMediaCell, ChannelMediaCellDelegate {
    var cachedImage: [String:UIImage]? = [:]
    @IBOutlet weak var messageImageViewContainer: UIView! {
        didSet {
            messageImageViewContainer.round(radius: 10.0)
        }
    }
    @IBOutlet weak var messageImageView: UIImageView! {
        didSet {
            messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
            messageImageView.contentMode = .scaleAspectFill
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
    }

    @objc
    func didTappedOnImage() {
        guard let message = self.message as? TextMessage, let attachment = message.attachment else { return }
        
        if attachment.isVideo {
            /// Will open video player
            self.onImageTapped?(attachment, nil)
        } else if attachment.isImage, let image = self.messageImageView.image {
            /// Will show full-screen image viewer
            self.onImageTapped?(attachment, image)
        }
    }

    // MARK: - ChannelMediaCellDelegate
    func didLoadAttachment(_ image: UIImage?) {
        if let image = image, self.cachedImage == nil {
            self.cachedImage?[self.message?.messageID ?? ""] = image
        }
    }
}
