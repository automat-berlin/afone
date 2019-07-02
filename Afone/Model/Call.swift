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
import CocoaLumberjack

@objc protocol CallDelegate: class {
    func stateChanged(_ callState: Call.CallState, for call: Call)
    func call(_ call: Call, isReceivingVideo: Bool)
    func call(_ call: Call, isSendingVideo: Bool)
}

@objc protocol CallDurationDelegate: class {
    func durationChanged(_ duration: TimeInterval, for call: Call)
    func durationStringChanged(_ durationString: String, for call: Call)
}

@objc class Call: NSObject {

    @objc enum CallState: Int {
        case unknown = 0
        case initialized    // Call is initialized
        case dialing        // Dialing
        case ringing        // Current device got incoming call
        case answering      // Waiting for call to be connected
        case talking        // Call session is in talking mode
        case holding        // Call is on hold
        case terminated     // Call has ended
    }

    private let voipManager: VoIPManager
    private let observers = NSHashTable<CallDelegate>.weakObjects()
    private var timer: Timer?
    private let formatter = DateComponentsFormatter()
    weak var durationDelegate: CallDurationDelegate?

    var uuid = UUID()
    var sessionId: Int = -1
    var caller = Constants.Call.unknownUser
    var callee = Constants.Call.unknownUser
    var existsAudio = false
    var isSendingVideo = false {
        didSet {
            observers.allObjects.forEach { observer in
                observer.call(self, isSendingVideo: isSendingVideo)
            }
        }
    }
    var isMute = false
    var isOnHold = false
    var isMissed = false
    var isIncomingCall = false
    var isOnSpeaker = false
    var isHungUpRemotely = false
    var duration: TimeInterval = 0
    var durationString = "00:00" {
        didSet {
            durationDelegate?.durationStringChanged(durationString, for: self)
        }
    }
    var callerDisplayName: String?
    var isReceivingVideo = false {
        didSet {
            observers.allObjects.forEach { observer in
                observer.call(self, isReceivingVideo: isReceivingVideo)
            }
        }
    }

    var callState: CallState {
        didSet {
            guard callState != oldValue else {
                return
            }
            if callState == .talking {
                if timer == nil {
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (_) in
                        guard let self = self else {
                            return
                        }
                        self.duration += 1
                        self.durationDelegate?.durationChanged(self.duration, for: self)
                        self.generateDurationString(for: self.duration)
                    })
                }
            }

            if callState == .terminated {
                timer?.invalidate()
                timer = nil
            }

            observers.allObjects.forEach { observer in
                observer.stateChanged(callState, for: self)
            }
        }
    }

    init(voipManager: VoIPManager) {
        self.voipManager = voipManager
        callState = .unknown
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
    }

    var callStateString: String {
        var stateString = ""
        switch callState {
        case .unknown:
            stateString = NSLocalizedString("unknown", comment: "")
        case .initialized:
            stateString = NSLocalizedString("initialized", comment: "")
        case .dialing:
            stateString = NSLocalizedString("dialing", comment: "")
        case .ringing:
            stateString = NSLocalizedString("ringing", comment: "")
        case .answering:
            stateString = NSLocalizedString("answering", comment: "")
        case .talking:
            stateString = NSLocalizedString("talking", comment: "")
        case .holding:
            stateString = NSLocalizedString("holding", comment: "")
        case .terminated:
            stateString = NSLocalizedString("terminated", comment: "")
        }

        return stateString
    }
}

// MARK: Duration

extension Call {
    private func generateDurationString(for duration: TimeInterval) {
        guard let newDurationString = formatter.string(from: duration) else {
            return
        }
        durationString = newDurationString
    }
}

// MARK: Call actions

extension Call {

    func accept(completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        voipManager.answerCall(sessionId, videoCall: true) { (error) in
            if error == nil {
                callState = .talking
            }

            completion(error)
        }
    }

    func hangup(completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        voipManager.hangUp(sessionId) { (error) in
            if error == nil {
                self.callState = .terminated
            }

            completion(error)
        }
    }

    func reject(completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        callState = .terminated

        voipManager.rejectCall(sessionId, code: Constants.Call.callRejectedCode) { (error) in
            completion(error)
        }
    }

    func mute(_ mute: Bool, completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        voipManager.mute(sessionId, mute: mute) { (error) in
            if error == nil {
                isMute = mute
            }

            completion(error)
        }
    }

    func hold(completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        voipManager.hold(sessionId) { (error) in
            if error == nil {
                isOnHold = true
            } else {
                isOnHold = false
            }

            completion(error)
        }
    }

    func unHold(completion: @escaping (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        voipManager.unhold(sessionId) { (error) in
            if error == nil {
                isOnHold = false
            } else {
                isOnHold = true
            }

            completion(error)
        }
    }

    func sendDTMF(character: Character) {
        voipManager.sendDTMF(sessionId, character: character)
    }
}

// MARK: Observers

extension Call {
    func addObserver(_ observer: CallDelegate) {
        observers.add(observer)
    }

    func removeObserver(_ observer: CallDelegate) {
        observers.remove(observer)
    }

    func removeAllObservers() {
        observers.removeAllObjects()
    }

    func showObservers() -> NSHashTable<CallDelegate> {
        return observers
    }
}
