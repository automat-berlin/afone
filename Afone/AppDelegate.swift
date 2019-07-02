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
import CocoaLumberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var backgroundTaskToken = UIBackgroundTaskIdentifier.invalid
    let dependencyProvider = DependencyProvider()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if application.applicationState == .background {
            startBackgroundTask(for: application)
        }

        DDLogInfo("App Started")

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        stopBackgroundTask(for: application)
        startBackgroundTask(for: application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        stopBackgroundTask(for: application)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType != "INStartAudioCallIntent" &&
            userActivity.activityType != "INStartVideoCallIntent" {
            return false
        }

        if dependencyProvider.callKitManager.activeCall != nil {
            dependencyProvider.voipManager.updateCall(with: userActivity.isVideoIntent)
        } else {
            let callOperation = CallOperation(userActivity: userActivity, dependencyProvider: dependencyProvider)
            dependencyProvider.operationQueue.addOperation(callOperation)
        }

        return true
    }
}

// MARK: Background Tasks

extension AppDelegate {

    private func startBackgroundTask(for application: UIApplication) {
        self.backgroundTaskToken = application.beginBackgroundTask {
            application.endBackgroundTask(self.backgroundTaskToken)
            self.backgroundTaskToken = .invalid
        }
    }

    private func stopBackgroundTask(for application: UIApplication) {
        if self.backgroundTaskToken != .invalid {
            application.endBackgroundTask(self.backgroundTaskToken)
            self.backgroundTaskToken = .invalid
        }
    }
}
