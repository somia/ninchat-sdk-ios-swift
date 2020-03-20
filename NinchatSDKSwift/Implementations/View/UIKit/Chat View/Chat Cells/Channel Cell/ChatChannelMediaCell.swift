//
// Copyright (c) 29.2.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol ChannelMediaCell {
    /// Outlets
    var messageImageViewContainer: UIView! { get set }
    var messageImageView: UIImageView! { get set }
    var videoPlayIndicator: UIImageView! { get set }
    
    func populateText(message: TextMessage, attachment: FileInfo?)
}

extension ChannelMediaCell where Self:ChatChannelCell {
    func populateText(message: TextMessage, attachment: FileInfo?) {
        attachment?.updateInfo(session: self.session) { [unowned self] error, didRefreshNetwork in
            guard error == nil else { return }
            do {
                try self.updateAttachment(asynchronous: didRefreshNetwork || self.messageImageView.height == nil)
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
            self.updateImage(from: attachment, imageURL: imageURL, asynchronous)
        } else if attachment.isVideo, let videoURL = attachment.url {
            self.videoPlayIndicator.isHidden = false
            self.messageImageView.contentMode = .scaleAspectFill
            try self.updateVideo(from: attachment, videoURL: videoURL, asynchronous)
        }
    }
    
    /// Update constraints to match new thumbnail image size
    private func updateVideo(from attachment: FileInfo, videoURL: String, _ asynchronous: Bool) throws {
        guard let thumbnailManager = self.videoThumbnailManager else { throw NINUIExceptions.noThumbnailManager }
        
        /// For video we must fetch the thumbnail image
        thumbnailManager.fetchVideoThumbnail(fromURL: videoURL) { [unowned self] error, fromCache, thumbnail in
            DispatchQueue.main.async {
                guard let image = thumbnail, error == nil else {
                    Toast.show(message: .error("Failed to get video thumbnail")); return
                }
                
                self.messageImageView.image = image
                self.set(aspect: CGFloat(attachment.aspectRatio ?? 1))
                
                guard !self.isReloading && asynchronous else { return }
                /// Inform the chat view that our cell might need resizing due to new constraints.
                /// We do this regardless of fromCache -value as this method may have been called asynchronously
                /// from `updateInfo(session:completion:)` completion block in populate method.
                self.onConstraintsUpdate?()
            }
        }
    }
    
    /// asynchronous = YES implies we're calling this asynchronously from the
    /// `updateInfo(session:completion:)` completion block (meaning it did a network update)
    private func updateImage(from attachment: FileInfo, imageURL: String, _ asynchronous: Bool) {
        DispatchQueue.main.async {
            /// Load the image in message image view over HTTP or from local cache
            self.messageImageView.image(from: imageURL)
            self.set(aspect: CGFloat(attachment.aspectRatio ?? 1))
            
            guard !self.isReloading && asynchronous else { return }
            /// Inform the chat view that our cell might need resizing due to new constraints.
            self.onConstraintsUpdate?()
        }
    }
    
    private func set(aspect ratio: CGFloat) {
        /// Return if the constraints are currently set
        if let _ = self.messageImageViewContainer.width { return }
        
        let width: CGFloat = (min(self.contentView.bounds.width, 400) / 3) * 2
        self.messageImageViewContainer.fix(width: width, height: width * (1/ratio))
        self.messageImageViewContainer.height?.priority = .defaultHigh
        self.messageImageViewContainer.width?.priority = .defaultHigh
    
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    private func resetImageLayout() {
        self.messageImageView.image = nil
        self.messageImageViewContainer.gestureRecognizers?.forEach { self.messageImageViewContainer.removeGestureRecognizer($0) }
    }
}

final class ChatChannelMediaMineCell: ChatChannelMineCell, ChannelMediaCell {
    @IBOutlet weak var messageImageViewContainer: UIView! {
        didSet {
            messageImageViewContainer.round(radius: 10.0)
        }
    }
    @IBOutlet weak var messageImageView: UIImageView! {
        didSet {
            messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
        }
    }
    @IBOutlet weak var videoPlayIndicator: UIImageView! {
        didSet {
            videoPlayIndicator.tintColor = .white
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.messageImageView.image = nil
        self.videoPlayIndicator.isHidden = true
    }
    
    @objc
    func didTappedOnImage() {
        guard let message = super.message as? TextMessage, let attachment = message.attachment else { return }
        
        if attachment.isVideo {
            /// Will open video player
            self.onImageTapped?(attachment, nil)
        } else if attachment.isImage, let image = self.messageImageView.image {
            /// Will show full-screen image viewer
            self.onImageTapped?(attachment, image)
        }
    }
}

final class ChatChannelMediaOthersCell: ChatChannelOthersCell, ChannelMediaCell {
    @IBOutlet var messageImageViewContainer: UIView! {
        didSet {
            messageImageViewContainer.round(radius: 10.0)
        }
    }
    @IBOutlet var messageImageView: UIImageView! {
        didSet {
            messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnImage)))
        }
    }
    @IBOutlet var videoPlayIndicator: UIImageView! {
        didSet {
            videoPlayIndicator.tintColor = .white
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.messageImageView.image = nil
        self.videoPlayIndicator.isHidden = true
    }
    
    @objc
    func didTappedOnImage() {
        guard let message = super.message as? TextMessage, let attachment = message.attachment else { return }
        
        if attachment.isVideo {
            /// Will open video player
            self.onImageTapped?(attachment, nil)
        } else if attachment.isImage, let image = self.messageImageView.image {
            /// Will show full-screen image viewer
            self.onImageTapped?(attachment, image)
        }
    }
}
