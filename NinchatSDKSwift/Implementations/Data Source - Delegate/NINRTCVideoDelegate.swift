//
// Copyright (c) 25.12.2019 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import WebRTC

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
