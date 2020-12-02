//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import UIKit

extension UIImageView {
    func image(from url: String?, aspectRatio: CGFloat = 1, completion: ((Data) -> Void)? = nil) {
        guard let urlStr = url  else { return }
        self.image(from: URL(string: urlStr), aspectRatio: aspectRatio, completion: completion)
    }
    
    func image(from url: URL?, aspectRatio: CGFloat = 1, completion: ((Data) -> Void)? = nil) {
        guard let url = url else { return }
    
        URLSession.shared.dataTask(with: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)) { (data: Data?, response: URLResponse?, error: Error?) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil
            else { return }
        
            DispatchQueue.main.async() { [weak self] in
                guard let `self` = self, let image = data.downsample(view: self, aspectRatio: aspectRatio) ?? UIImage(data: data) else { return }
                self.image = image
                completion?(data)
            }
        }.resume()
    }

    func fetchImage(from url: URL?, aspectRatio: CGFloat = 1, completion: ((UIImage, UIImage) -> Void)? = nil) {
        guard let url = url else { return }
        URLSession.shared.dataTask(with: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)) { (data: Data?, response: URLResponse?, error: Error?) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil
            else { return }

            DispatchQueue.main.async() { [weak self] in
                guard let `self` = self, let image = UIImage(data: data), let thumbnail = data.downsample(view: self, aspectRatio: aspectRatio) else { return }
                completion?(image, thumbnail)
            }
        }.resume()
    }

    var tint: UIColor? {
        set {
            self.image = self.image?.withRenderingMode(.alwaysTemplate)
            self.tintColor = newValue
        }
        get {
            self.tintColor
        }
    }
}

extension Data {
    /// inspired from the article  https://swiftsenpai.com/development/reduce-uiimage-memory-footprint/
    
    fileprivate func downsample(view: UIView, aspectRatio: CGFloat) -> UIImage? {
        // Create an CGImageSource that represent an image
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, [kCGImageSourceShouldCache: true] as CFDictionary) else { return nil }
                
        // Perform downsampling
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Swift.max(view.width?.constant ?? view.bounds.width, view.height?.constant ?? view.bounds.height) * aspectRatio // Calculate the desired dimension
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        // Return the downsampled image as UIImage
        return UIImage(cgImage: downsampledImage)
    }
}
