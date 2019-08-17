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
import PushKit
import CocoaLumberjack

@objc protocol PushPayloadObserver: class {
    func didUpdatePushToken(_ token: Data)
    func didReceivePayload(_ payload: [AnyHashable: Any])
    func didInvalidatePushToken()
}

protocol PushPayloadProvider: class {
    func addObserver(_ observer: PushPayloadObserver)
    func removeObserver(_ observer: PushPayloadObserver)
    func removeAllObservers()
}

protocol PushRegistryHandlerDelegate: class {
    func handleIncomingPushPayload(_ payload: PKPushPayload)
}

class PushRegistryHandler: NSObject {
    private var pendingPayloads = [PKPushPayload]()
    private let observers = NSHashTable<PushPayloadObserver>.weakObjects()

    weak var delegate: PushRegistryHandlerDelegate? {
        didSet {
            handlePendingPayloads()
        }
    }

    override init() {
        super.init()

        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([.voIP])

        DDLogInfo("Registering VoIP notifications")
    }

    private func handlePendingPayloads() {
        guard let delegate = delegate else { return }

        for payload in pendingPayloads {
            delegate.handleIncomingPushPayload(payload)
        }

        pendingPayloads.removeAll()
    }
}

extension PushRegistryHandler: PushPayloadProvider {

    func addObserver(_ observer: PushPayloadObserver) {
        observers.add(observer)
    }

    func removeObserver(_ observer: PushPayloadObserver) {
        observers.remove(observer)
    }

    func removeAllObservers() {
        observers.removeAllObjects()
    }
}

extension PushRegistryHandler: PKPushRegistryDelegate {
    // MARK: PKPushRegistryDelegate

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        //Casting from Data to NSData always succeeds
        let token: String = credentials.token.hexString

        DDLogInfo("Did receive push credentials for type \(type) \(credentials) \(token)")

        observers.allObjects.forEach({ observer in
            observer.didUpdatePushToken(credentials.token)
        })
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        DDLogInfo("Got VoIP push: \(type) \(payload)")

        observers.allObjects.forEach({ observer in
            observer.didReceivePayload(payload.dictionaryPayload)
        })

        if let delegate = delegate {
            delegate.handleIncomingPushPayload(payload)
        } else {
            pendingPayloads.append(payload)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        observers.allObjects.forEach({ observer in
            observer.didInvalidatePushToken()
        })
    }
}
