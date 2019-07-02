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

import Foundation
import UserNotifications

class LocalNotificationManager {
    private static let kNotificationCategoryRejectedCall = "berlin.automat.localnotification.category.rejected.call"

    static func showRejectedCallNotification(call: Call) {
        let content = UNMutableNotificationContent()
        content.title = String(format: NSLocalizedString("%@ tried to reach you", comment: ""), call.caller)
        content.body = NSLocalizedString("Due to missing microphone and camera permissions, the call was rejected automatically.", comment: "")
        content.categoryIdentifier = LocalNotificationManager.kNotificationCategoryRejectedCall
        content.sound = .default

        let notificationRequest = UNNotificationRequest(identifier: call.uuid.uuidString, content: content, trigger: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
        }
    }
}
