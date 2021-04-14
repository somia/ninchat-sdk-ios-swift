//
// Copyright (c) 14.4.2021 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Photos

extension PHAssetResourceType {
    var fileExtension: String? {
        switch self {
        case .video, .fullSizeVideo, .pairedVideo, .fullSizePairedVideo, .adjustmentBasePairedVideo, .adjustmentBaseVideo:
            return ".mp4"
        case .photo, .alternatePhoto, .fullSizePhoto, .adjustmentBasePhoto:
            return ".jpg"
        default:
            return nil
        }
    }
}
