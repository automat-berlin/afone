//
// Automat
//
// Copyright (c) 2019 Automat Berlin GmbH - https://automat.berlin/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import UserNotifications
import AVFoundation

enum CallPermission {
    case audio
    case video

    var mediaType: AVMediaType {
        switch self {
        case .audio:
            return AVMediaType.audio
        case .video:
            return AVMediaType.video
        }
    }

    var errorMessage: String {
        switch self {
        case .audio:
            return "Used for audio calls."
        case .video:
            return "Used for video calls."
        }
    }
}

class Permissions {

    // MARK: Notification Permissions

    static func isNotificationPermissionAuthorized(completionHandler: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            completionHandler(isAuthorized)
        }
    }

    static func requestNotificationPermission(completionHandler: ((Bool, Error?) -> Void)?) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (isAuthorized, error) in
            completionHandler?(isAuthorized, error)
        }
    }

    static func isNotificationPermissionDenied(completionHandler: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isDenied = settings.authorizationStatus == .denied
            completionHandler(isDenied)
        }
    }

    // MARK: Mic and Camera Permissions for Calling

    static func requestCallPermissions(_ permissions: [CallPermission], completionHandler: @escaping ((Bool) -> Void)) {

        let dispatchGroup = DispatchGroup()

        var permissionError: String?

        for permission in permissions {
            guard permissionError == nil else { break }

            switch AVCaptureDevice.authorizationStatus(for: permission.mediaType) {
            case .notDetermined:
                dispatchGroup.enter()

                AVCaptureDevice.requestAccess(for: permission.mediaType) { granted in
                    if !granted {
                        permissionError = permission.errorMessage
                    }

                    dispatchGroup.leave()
                }
            case .restricted, .denied:
                permissionError = permission.errorMessage
            case .authorized:
                break
            @unknown default:
                fatalError("Authorization status not covered. See Permissions.swift.")
            }
        }

        dispatchGroup.notify(queue: .main) {
            if permissionError == nil {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }

    static func isCameraPermissionAuthorized() -> Bool {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return cameraAuthorizationStatus != .denied
    }

    static var isMicrophonePermissionDenied: Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .denied
    }

    static var isMicrophonePermissionAuthorized: Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
}
