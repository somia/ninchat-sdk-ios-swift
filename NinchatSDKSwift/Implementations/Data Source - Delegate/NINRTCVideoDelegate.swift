//
//  NINRTCVideoDelegate.swift
//  NinchatSDKSwift
//
//  Created by Hassan Shahbazi on 25.12.2019.
//  Copyright © 2019 Hassan Shahbazi. All rights reserved.
//

import Foundation
import NinchatSDK

protocol NINRTCVideoActions {
    var onSizeChange: ((CGSize) -> Void)? { get set }
}

protocol NINRTCVideoDelegate: RTCVideoViewDelegate, NINRTCVideoActions {}

final class NINRTCVideoDelegateImpl: NINRTCVideoDelegate {
    
    // MARK: - NINRTCVideoActions
    
    var onSizeChange: ((CGSize) -> Void)?
}

// MARK: - RTCVideoViewDelegate

extension NINRTCVideoDelegateImpl {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        self.onSizeChange?(size)
    }

}
