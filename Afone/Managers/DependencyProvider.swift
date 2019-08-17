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

class DependencyProvider {

    let pushRegistryManager = PushRegistryHandler()
    let callKitManager = CallKitManager()
    let dtmfManager = DTMFManager()
    let keychainManager = KeychainManager()

    private let adapter: VoIPManagerDelegate

    let voipManager = VoIPManager()
    var credentials = Credentials()
    var settings: Settings = Settings()
    let calling: Calling

    let operationQueue = OperationQueue()

    weak var tabBarController: ViewController? {
        didSet {
            operationQueue.isSuspended = false
        }
    }

    init() {
        Logging.configure()

        calling = Calling(callKitManager: callKitManager)
        adapter = PortSIPAdapter(voipManager: voipManager)
//        adapter = AbtoAdapter(voipManager: voipManager)
//        adapter = TwilioVoiceAdapter(voipManager: voipManager)
//        pushRegistryManager.addObserver(adapter as! TwilioVoiceAdapter)

        voipManager.delegate = adapter
        voipManager.dependencyProvider = self
        voipManager.addObserver(callKitManager)
        callKitManager.delegate = voipManager
        settings.load()

        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true
    }
}

// MARK: - Business logic

// Maybe in the future this should be done in some kind of App Client
extension DependencyProvider {
    private func clearAll() {
        credentials = Credentials()
        keychainManager.clearAll()
        settings.clear()
    }

    func logout(completion: @escaping () -> Void) {
        clearAll()
        voipManager.logout(completion: completion)
    }

    func reloadSettings() {
        voipManager.reload(with: settings)
    }
}
