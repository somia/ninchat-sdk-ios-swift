//
// Copyright (c) 25.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import Photos
import CoreServices

enum AttachmentError: Error {
    case unsupported

    var localizedDescription: String {
        switch self {
        case .unsupported:
            return "Unsupported attachment".localized
        }
    }
}

protocol NINPickerControllerAction {
    var onMediaSent: ((Error?) -> Void)? { get set }
    var onDismissPicker: (() -> Void)? { get set }
}

protocol NINPickerControllerDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate, NINPickerControllerAction {
    init(viewModel: NINChatViewModel)
}

final class NINPickerControllerDelegateImpl: NSObject, NINPickerControllerDelegate {
    
    // MARK: - NINPickerControllerAction
    
    var onMediaSent: ((Error?) -> Void)?
    var onDismissPicker: (() -> Void)?
    
    // MARK: - NINPickerControllerDelegate
    
    private let viewModel: NINChatViewModel
    
    init(viewModel: NINChatViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - UIImagePickerControllerDelegate

extension NINPickerControllerDelegateImpl {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { self.onDismissPicker?() }
        var fileName = UUID().uuidString

        /// Photos from photo library have file names; extract it
        if picker.sourceType == .photoLibrary {
            if #available(iOS 11, *) {
                if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset,
                   let assetResource = PHAssetResource.assetResources(for: asset).last {

                    /// other types are not supported
                    /// PDF documents cannot be selected from 'photo library'
                    guard assetResource.type == .video || assetResource.type == .photo else {
                        self.viewModel.onErrorOccurred?(AttachmentError.unsupported)
                        return
                    }

                    /// avoid sending file's original extension to avoid confusion
                    /// in the following lines we convert the image to jpg
                    let fileExtension = (assetResource.type == .video) ? ".mp4" : ".jpg"

                    /// use asset UUID to get the unique name for the asset
                    fileName = assetResource.assetLocalIdentifier.components(separatedBy: "/").first! + fileExtension
                }
            } else {
                if let url = info[UIImagePickerController.InfoKey.referenceURL] as? URL,
                   let phAsset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).lastObject,
                   let name = phAsset.value(forKey: "filename") as? String {

                    fileName = name
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            switch info[UIImagePickerController.InfoKey.mediaType] as! CFString {
            case kUTTypeImage:
                if fileName.components(separatedBy: ".").count == 1 {
                    /// extension was not set
                    fileName += ".jpg"
                }

                if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.5) {
                    self.viewModel.send(attachment: fileName, data: data) { [weak self] error in
                        self?.onMediaSent?(error)
                    }
                }
            case kUTTypeMovie:
                if fileName.components(separatedBy: ".").count == 1 {
                    /// extension was not set
                    fileName += ".mp4"
                }

                if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL, let data = try? Data(contentsOf: videoURL) {
                    self.viewModel.send(attachment: fileName, data: data) { [weak self] error in
                        self?.onMediaSent?(error)
                    }
                }
            default:
                self.viewModel.onErrorOccurred?(AttachmentError.unsupported)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.onDismissPicker?()
    }
}
