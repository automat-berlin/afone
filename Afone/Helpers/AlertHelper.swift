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

class AlertHelper {

    static func showPermissionsAlert(on viewController: UIViewController?) {
        let title = NSLocalizedString("Missing Permissions", comment: "")
        let message = NSLocalizedString("In order to make a call you need to grant //afone access to the microphone and camera. Please go to Settings to do so.", comment: "")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { _ in
            openSettings()
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)

        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)

        viewController?.present(alertController, animated: true, completion: nil)
    }

    static func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }

    static func showLogoutConfirmation(on viewController: UIViewController, completion: (() -> Void)?) {
        let title = NSLocalizedString("Logout", comment: "")
        let message = NSLocalizedString("Are you sure you want to log out?", comment: "")
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        let logoutAction = UIAlertAction(title: NSLocalizedString("Logout", comment: ""), style: .destructive) { _ in
            completion?()
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)

        actionSheet.addAction(logoutAction)
        actionSheet.addAction(cancelAction)

        viewController.present(actionSheet, animated: true, completion: nil)
    }

    static func showNoCodecsAlert(on viewController: UIViewController?) {
        let title = NSLocalizedString("No codecs selected", comment: "")
        let message = NSLocalizedString("""
            In order to make a call you need to select at least one audio codec.
            Please go to Settings and select audio/video codecs supported by your backend.
            """, comment: "")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)

        alertController.addAction(okAction)

        viewController?.present(alertController, animated: true, completion: nil)

    }

    static func showPhoneNumberSheet(on viewController: UIViewController, phoneNumbers: [String], completion: ((String) -> Void)?) {
        let title = NSLocalizedString("Phone numbers", comment: "")
        let message = NSLocalizedString("Which phone number would you like to call?", comment: "")
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        _ = phoneNumbers.map({ number in
            let action = UIAlertAction(title: number, style: .default) { _ in
                completion?(number)
            }
            actionSheet.addAction(action)
        })

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)

        viewController.present(actionSheet, animated: true, completion: nil)
    }
}
