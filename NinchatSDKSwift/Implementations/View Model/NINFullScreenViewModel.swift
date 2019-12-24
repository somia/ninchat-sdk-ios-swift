//
//  NINFullScreenViewModel.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 24.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import UIKit

protocol NINFullScreenViewModel {
    init(session: NINChatSessionSwift)
    func download(image: UIImage, completion: @escaping ((Error?) -> Void))
}

final class NINFullScreenViewModelImpl: NINFullScreenViewModel {
    
    private unowned let session: NINChatSessionSwift
    private var downloadCompletion: ((Error?) -> Void)?
    
    // MARK: - NINFullScreenViewModel
    
    init(session: NINChatSessionSwift) {
        self.session = session
    }
    
    func download(image: UIImage, completion: @escaping ((Error?) -> Void)) {
        downloadCompletion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didSaved(_:error:)), nil)
    }
}

extension NINFullScreenViewModelImpl {
    @objc
    private func didSaved(_ image: UIImage, error: Error?) {
        if let error = error {
            self.session.ninchat(session, didOutputSDKLog: "Error: failed to save image to Photos album: \(error)")
        }
        downloadCompletion?(error)
    }
}
