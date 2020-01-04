//
// Copyright (c) 25.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import Photos
import CoreServices

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
        var fileName = "photo.jpg"
        
        // Photos from photo library have file names; extract it
        if #available(iOS 11, *) {
            if picker.sourceType == .photoLibrary,
                let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset,
                let assetResource = PHAssetResource.assetResources(for: asset).last {
                
                fileName = assetResource.originalFilename
            }
        } else {
            if picker.sourceType == .photoLibrary,
                let url = info[UIImagePickerController.InfoKey.referenceURL] as? URL,
                let phAsset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).lastObject,
                let name = phAsset.value(forKey: "filename") as? String {
                
                fileName = name
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            switch info[UIImagePickerController.InfoKey.mediaType] as! CFString {
            case kUTTypeImage:
                if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let data = image.jpegData(compressionQuality: 1.0) {
                    self.viewModel.send(attachment: fileName, data: data) { [weak self] error in
                        self?.onMediaSent?(error)
                    }
                }
            case kUTTypeMovie:
                if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL, let data = try? Data(contentsOf: videoURL) {
                    self.viewModel.send(attachment: fileName, data: data) { [weak self] error in
                        self?.onMediaSent?(error)
                    }
                }
            default:
                fatalError("Invalid media type!")
            }
        }
        self.onDismissPicker?()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.onDismissPicker?()
    }
}
