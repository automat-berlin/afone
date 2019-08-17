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
import CallKit
import CocoaLumberjack
import AVFoundation

protocol CallKitManagerDelegate: class {
    func performStartCall(to: String, hasVideo: Bool, completion: (Call?, NSError?) -> Void)
    func callKitShouldStartAudio()
    func callKitShouldStopAudio()
}

protocol CallKitManagerAudioStateDelegate: class {
    func callKitDidMuteCall(_ isMuted: Bool)
    func callKitDidHoldCall(_ isOnHold: Bool)
}

class CallKitManager: NSObject {

    weak var delegate: CallKitManagerDelegate?
    weak var audioStateDelegate: CallKitManagerAudioStateDelegate?

    private let provider: CXProvider
    private let callController: CXCallController
    var activeCall: Call? {
        didSet {
            activeCall?.addObserver(self)
        }
    }

    override init() {
        let providerConfiguration = CXProviderConfiguration(localizedName: Bundle.main.appName)

        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.iconTemplateImageData = UIImage(named: "callkit")?.pngData()

        provider = CXProvider(configuration: providerConfiguration)
        callController = CXCallController()

        super.init()

        provider.setDelegate(self, queue: nil)
    }
}

extension CallKitManager: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        requestEndCall(completion: nil)
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        delegate?.performStartCall(to: action.handle.value, hasVideo: action.isVideo) { [weak self] (call, _) in
            if let call = call {
                action.fulfill()
                call.uuid = action.callUUID
                self?.activeCall = call
            } else {
                action.fail()
            }
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard activeCall?.uuid == action.callUUID else {
            action.fail()
            return
        }

        activeCall?.accept(completion: { (error: Error?) in
            if error != nil {
                action.fail()
            } else {
                action.fulfill()
            }
        })
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let activeCall = activeCall,
            activeCall.uuid == action.callUUID else {
            action.fail()
            return
        }

        if activeCall.callState == .talking {
            activeCall.hangup(completion: { [weak self] (error: Error?) in
                if error != nil {
                    action.fail()
                } else {
                    action.fulfill()
                }

                self?.activeCall = nil
            })
        } else if activeCall.callState == .terminated && activeCall.isHungUpRemotely {
            provider.reportCall(with: activeCall.uuid, endedAt: nil, reason: .remoteEnded)
        } else {
            activeCall.reject(completion: { [weak self] (error: Error?) in
                if error != nil {
                    action.fail()
                } else {
                    action.fulfill()
                }

                self?.activeCall = nil
            })
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard activeCall?.uuid == action.callUUID,
            let isMute = activeCall?.isMute else {
                action.fail()
                return
        }

        activeCall?.mute((!isMute), completion: { [weak self] (error: Error?) in
            if error != nil {
                action.fail()
                DDLogError("Unable to mute call: \(!isMute) with error: \(String(describing: error?.localizedDescription)).")
            } else {
                action.fulfill()
                self?.audioStateDelegate?.callKitDidMuteCall(!isMute)
            }
        })
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard activeCall?.uuid == action.callUUID,
            let isOnHold = activeCall?.isOnHold else {
            action.fail()
            return
        }

        if isOnHold && !action.isOnHold {
            activeCall?.unHold(completion: { [weak self] (error: Error?) in
                if error != nil {
                    action.fail()
                    DDLogError("Unable to unhold call: \(String(describing: error?.localizedDescription)).")
                } else {
                    action.fulfill()
                    self?.audioStateDelegate?.callKitDidHoldCall(false)
                }
            })
        } else if !isOnHold && action.isOnHold {
            activeCall?.hold(completion: { [weak self] (error: Error?) in
                if error != nil {
                    action.fail()
                    DDLogError("Unable to hold call: \(String(describing: error?.localizedDescription)).")
                } else {
                    action.fulfill()
                    self?.audioStateDelegate?.callKitDidHoldCall(true)
                }
            })
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard activeCall?.uuid == action.callUUID else {
            action.fail()
            return
        }

        for digit in action.digits {
            activeCall?.sendDTMF(character: digit)
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        DDLogInfo("***** Did activate audio *****")
        delegate?.callKitShouldStartAudio()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        DDLogInfo("***** Did deactivate audio *****")
        delegate?.callKitShouldStopAudio()

        // restore audio session
        AudioSessionManager.configureAudioSession(type: .restore)
    }
}

extension CallKitManager: VoIPCallingProtocol {

    func gotIncomingCall(_ call: Call) {

        if !Permissions.isCameraPermissionAuthorized() && Permissions.isMicrophonePermissionDenied {
            call.isMissed = true
            call.reject { _ in
                DispatchQueue.main.async {
                    LocalNotificationManager.showRejectedCallNotification(call: call)
                }
            }
            return
        }

        activeCall = call

        AudioSessionManager.configureAudioSession(type: .voice)

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: call.caller)
        update.localizedCallerName = call.caller
        update.supportsDTMF = true
        update.supportsHolding = true
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.hasVideo = call.isReceivingVideo

        provider.reportNewIncomingCall(with: call.uuid, update: update) { [weak self] (error: Error?) in
            if error != nil {
                AudioSessionManager.configureAudioSession(type: .restore)
                self?.provider.reportCall(with: call.uuid, endedAt: nil, reason: .unanswered)
            }
        }
    }

    func didAnswerCall(_ call: Call) {
    }

    func gotMissedCall(_ call: Call) {
    }
}

// MARK: CallDelegate

extension CallKitManager: CallDelegate {
    func stateChanged(_ callState: Call.CallState, for call: Call) {
        switch callState {
        case .terminated:
            guard call.isHungUpRemotely else {
                return
            }
            requestEndCall { [weak self] (_) in
                self?.provider.invalidate()
            }
        case .talking:
            provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
        default:
            break
        }
    }

    func call(_ call: Call, isReceivingVideo: Bool) {
        let update = CXCallUpdate()
        update.hasVideo = isReceivingVideo
        provider.reportCall(with: call.uuid, updated: update)
    }

    func call(_ call: Call, isSendingVideo: Bool) {}
}

// MARK: Create Call, End Call

extension CallKitManager {
    func requestCall(to: String, hasVideo: Bool, completion: @escaping (Error?) -> Void) {
        let handle = CXHandle(type: .generic, value: to)
        let uuid = UUID()
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = hasVideo
        let transaction = CXTransaction(action: startCallAction)

        AudioSessionManager.configureAudioSession(type: .voice)

        callController.request(transaction) { [weak self] (error) in
            if error == nil {
                self?.provider.reportOutgoingCall(with: uuid, startedConnectingAt: nil)

                let update = CXCallUpdate()
                update.localizedCallerName = to
                update.hasVideo = hasVideo
                self?.provider.reportCall(with: uuid, updated: update)
            } else {
                DDLogError("Error while requesting call start: \(String(describing: error?.localizedDescription)).")

                AudioSessionManager.configureAudioSession(type: .restore)
                self?.provider.invalidate()
            }

            completion(error)
        }
    }

    func requestEndCall(completion: ((Error?) -> Void)?) {
        guard let call = activeCall else {
            return
        }
        let endAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction(action: endAction)

        callController.request(transaction, completion: { (error: Error?) in
            if error != nil {
                DDLogError("Error while requesting call end: \(String(describing: error?.localizedDescription)).")
            }

            completion?(error)
        })
    }
}

// MARK: Trigger Mute and Hold

extension CallKitManager {

    func triggerMute(_ isMuted: Bool, completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard let callUUID = activeCall?.uuid else {
            return
        }

        let muteAction = CXSetMutedCallAction(call: callUUID, muted: isMuted)
        let transaction = CXTransaction(action: muteAction)

        callController.request(transaction) { (callKitError) in
            if callKitError == nil {
                muteAction.fulfill()
            } else {
                muteAction.fail()
                error = NSError(domain: Constants.Call.domain, code: 1000, userInfo: ["description": "Trigger Mute/unMute failed"])
            }
            completion(error)
        }
    }

    func triggerHold(_ isOnHold: Bool, completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard let callUUID = activeCall?.uuid else {
            return
        }

        let holdAction = CXSetHeldCallAction(call: callUUID, onHold: isOnHold)
        let transaction = CXTransaction(action: holdAction)

        callController.request(transaction) { (callKitError) in
            if callKitError == nil {
                holdAction.fulfill()
            } else {
                holdAction.fail()
                error = NSError(domain: Constants.Call.domain, code: 1001, userInfo: ["description": "Trigger Hold/unHold failed"])
            }
            completion(error)
        }
    }
}
