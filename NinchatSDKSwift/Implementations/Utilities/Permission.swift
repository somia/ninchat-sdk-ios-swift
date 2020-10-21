//
// Copyright (c) 14.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import Photos

typealias PermissionCompletion = (PermissionError?) -> Void

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

final class PermissionStatus {
    var type: PermissionType
    var error: PermissionError?

    init(type: PermissionType) {
        self.type = type
    }

    func grant(queue: DispatchGroup) {
        queue.enter()
        switch type {
            case .deviceCamera:
                self.grantDeviceCamera { [weak self] error in
                    self?.error = error
                    queue.leave()
                }
            case .deviceMicrophone:
                self.grantDeviceMicrophone { [weak self] error in
                    self?.error = error
                    queue.leave()
                }
            case .devicePhotoLibrary:
                self.grantDevicePhotoLibrary { [weak self] error in
                    self?.error = error
                    queue.leave()
                }
            }
    }

    func grantDeviceMicrophone(_ onCompletion: @escaping PermissionCompletion) {
        self.grantMedia(media: .audio, onCompletion)
    }

    func grantDeviceCamera(_ onCompletion: @escaping PermissionCompletion) {
        self.grantMedia(media: .video, onCompletion)
    }

    func grantDevicePhotoLibrary(_ onCompletion: @escaping PermissionCompletion) {
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

    func grantMedia(media: AVMediaType, _ onCompletion: @escaping PermissionCompletion) {
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

struct Permission {
    static func grantPermission(_ types: PermissionType..., onCompletion: @escaping PermissionCompletion) {
        let dispatchGroup = DispatchGroup()
        let permissions = types.compactMap({ PermissionStatus(type: $0) }).map { (permission: PermissionStatus) -> PermissionStatus in
            permission.grant(queue: dispatchGroup); return permission
        }

        dispatchGroup.notify(queue: DispatchQueue.global(qos: .background)) {
            onCompletion( permissions.compactMap({ $0.error }).first )
        }
    }
}