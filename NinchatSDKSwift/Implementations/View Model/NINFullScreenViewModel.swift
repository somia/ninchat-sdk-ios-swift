//
// Copyright (c) 24.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit

protocol NINFullScreenViewModel {
    init(delegate: NINChatSessionInternalDelegate?)
    func download(image: UIImage, completion: @escaping (Error?) -> Void)
}

final class NINFullScreenViewModelImpl: NSObject, NINFullScreenViewModel {
    
    private var delegate: NINChatSessionInternalDelegate?
    private var downloadCompletion: ((Error?) -> Void)?
    
    // MARK: - NINFullScreenViewModel
    
    init(delegate: NINChatSessionInternalDelegate?) {
        self.delegate = delegate
    }

    func download(image: UIImage, completion: @escaping (Error?) -> Void) {
        downloadCompletion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.didSaved(_:error:context:)), nil)
    }
}

extension NINFullScreenViewModelImpl {
    @objc
    private func didSaved(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer) {
        if let error = error {
            self.delegate?.log(value: "Error: failed to save image to Photos album: \(error)")
        }
        downloadCompletion?(error)
    }
}
