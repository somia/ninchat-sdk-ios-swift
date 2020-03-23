//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import AVFoundation
import UIKit

struct VideoThumbnailManager {
    
    private let imageCache = NSCache<NSString, UIImage>()
    
    init() {
        self.imageCache.name = Constants.kNinchatImageCacheKey.rawValue
    }
    
    // MARK: - VideoThumbnailManager
    
    func fetchVideoThumbnail(fromURL url: String, completion: @escaping ((Error?, Bool, UIImage?) -> ())) {
        /// Check if we have a cached thumbnail
        if let cachedImage = self.imageCache.object(forKey: url as NSString) {
            completion(nil, true, cachedImage); return
        }
    
        /// Cache miss; must extract it from the video
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: URL(string: url)!)
            
            /// Grab the thumbnail a few seconds into the video
            let duration = asset.duration
            let thumbTime = CMTimeMaximum(duration, CMTime(seconds: 2, preferredTimescale: 30))
    
            /// Create an AVAssetImageGenerator that applies the proper image orientation
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            /// Extract the thumbnail image as a snapshot from a video frame
            do {
                let imageRef = try generator.copyCGImage(at: thumbTime, actualTime: nil)
                let thumbnail = UIImage(cgImage: imageRef)
                self.imageCache.setObject(thumbnail, forKey: url as NSString)
                completion(nil, false, thumbnail)
            } catch {
                completion(error, false, nil)
            }
        }
    }
}