//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import Photos

enum PermissionType {
    case deviceCamera
    case deviceMicrophone
    case devicePhotoLibrary
}

enum PermissionError: Error {
    case unknown
    case permissionDenied
    case permissionRestricted
}

struct Permission {
    typealias PermissionCompletion = ((PermissionError?) -> Void)
    static func grantPermission(_ type: PermissionType, onCompletion: @escaping PermissionCompletion) {
        switch type {
        case .deviceCamera: self.grantDeviceCamera(onCompletion)
        case .deviceMicrophone: self.grantDeviceMicrophone(onCompletion)
        case .devicePhotoLibrary: self.grantDevicePhotoLibrary(onCompletion)
        }
    }
    
    private static func grantDeviceMicrophone(_ onCompletion: @escaping PermissionCompletion) {
        self.grantMedia(media: .audio, onCompletion)
    }
    
    private static func grantDeviceCamera(_ onCompletion: @escaping PermissionCompletion) {
        self.grantMedia(media: .video, onCompletion)
    }
    
    private static func grantDevicePhotoLibrary(_ onCompletion: @escaping PermissionCompletion) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            debugger("`Photo library` is authorized.")
            onCompletion(nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { granted in
                debugger("User authorized the use of `Photo library`: \(granted)")
                granted == .authorized ? onCompletion(nil) : onCompletion(.permissionDenied)
            }
        case .restricted:
            debugger("`Photo library` is restricted!")
            onCompletion(.permissionRestricted)
        case .denied:
            debugger("`Photo library` is denied!")
            onCompletion(.permissionDenied)
        default:
            onCompletion(.unknown)
        }
    }
    
    // MARK: - Helper
    
    private static func grantMedia(media: AVMediaType, _ onCompletion: @escaping PermissionCompletion) {
        switch AVCaptureDevice.authorizationStatus(for: media) {
        case .authorized:
            debugger("`AVCaptureDevice` is already authorized.")
            onCompletion(nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: media) { granted in
                debugger("User authorized the use of `AVCaptureDevice`: \(granted)")
                granted ? onCompletion(nil) : onCompletion(.permissionDenied)
            }
        case .restricted:
            debugger("`AVCaptureDevice` is restricted!")
            onCompletion(.permissionRestricted)
        case .denied:
            debugger("`AVCaptureDevice` is denied!")
            onCompletion(.permissionDenied)
        default:
            onCompletion(.unknown)
        }
    }
}