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

class ViewController: UITabBarController, BaseViewControllerProtocol {
    var dependencyProvider: DependencyProvider {
        return (UIApplication.shared.delegate as! AppDelegate).dependencyProvider
    }

    private let callScreenSegueID = "showCallScreen"
    private var call: Call?
    private weak var callViewController: CallViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        dependencyProvider.voipManager.addObserver(self)

        // Explicitly set audio session to ambient with default mode, so that
        // the DTMF sounds in the dialer are more prominent.
        // It also fixes a random "no audio" bug in CallKit
        AudioSessionManager.configureAudioSession(type: .restore)

        // Ask for Notification permissions
        Permissions.requestNotificationPermission(completionHandler: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dependencyProvider.tabBarController = self
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    }

    func showCallScreen(sender: Any?, call: Call) {
        self.call = call
        performSegue(withIdentifier: callScreenSegueID, sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == callScreenSegueID {
            if let callViewController = segue.destination as? CallViewController {
                callViewController.call = call
                self.callViewController = callViewController
            }
        }
    }
}

extension ViewController: VoIPCallingProtocol {
    func gotIncomingCall(_ call: Call) {
    }

    func didAnswerCall(_ call: Call) {
        callViewController?.call = call
        showCallScreen(sender: self, call: call)
    }

    func gotMissedCall(_ call: Call) {
    }
}
