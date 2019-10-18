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
import TwilioVoice

class TwilioVoiceAdapter: NSObject {

    /// The current call.
    private var call: Call?

    // Call invite required for several Twilio API functions.
    private var twilioCallInvite: TVOCallInvite?

    // Call required for several Twilio API functions.
    private var twilioCall: TVOCall?
    private var audioDevice: TVODefaultAudioDevice = TVODefaultAudioDevice()

    /// The server credentials.
    private var credentials: Credentials?

    /// The application’s `VoIPManager` used to interact with a concrete adapter implementation.
    private let voipManager: VoIPManager

    /// Twilio specific temporary properties
    private var accessToken = ""
    private var deviceToken = ""

    /**
     Initializes the adapter.

    - Parameter voipManager: The application’s `VoIPManager` that can be used for call-related functionality, and which delegates to an adapter implementation.
    */
    init(voipManager: VoIPManager) {
        self.voipManager = voipManager

        super.init()
        TwilioVoice.audioDevice = audioDevice
    }

    /**
     Get accessToken

     - Parameter credentials: The credentials that should be used for a login.
     - Parameter completion: The block to execute after a login.
     */
    private func login(credentials: Credentials, completion: @escaping (NSError?) -> Void) {
        self.credentials = credentials

        if let accessToken = fetchAccessToken() {
            self.accessToken = accessToken
            completion(nil)
        } else {
            let error = NSError(domain: "TwilioVoiceAdapter", code: 501, userInfo: ["description": "Couldn't retrieve accessToken"])
            completion(error)
        }
    }

    private func fetchAccessToken() -> String? {
        guard let login = credentials?.login,
            let endpoint = credentials?.sipServer else {
            return nil
        }
        let endpointWithIdentity = String(format: "?identity=%@", login)
        guard let accessTokenURL = URL(string: endpoint + endpointWithIdentity) else {
            return nil
        }

        return try? String.init(contentsOf: accessTokenURL, encoding: .utf8)
    }
}

// MARK: - VoIPManagerDelegate

extension TwilioVoiceAdapter: VoIPManagerDelegate {
    func cancelLogin() {

    }

    var supportsVideo: Bool {
        return false
    }

    var needsCodecs: Bool {
        return false
    }

    var remoteVideoView: UIView? {
        return nil
    }

    var localVideoView: UIView? {
        return nil
    }

    func reload(with settings: Settings) {
    }

    var srtpOptions: [SRTP] {
        return []
    }

    var audioCodecs: [Codec] {
        return []
    }

    var videoCodecs: [Codec] {
        return []
    }

    func logout(completion: (() -> Void)?) {
        accessToken = ""
        completion?()
    }

    func didEnterBackground() {
    }

    func willEnterForeground() {
    }

    func initAdapter(credentials: Credentials, completion: @escaping (NSError?) -> Void) {
        login(credentials: credentials, completion: completion)
    }

    func answerCall(_ sessionId: Int, videoCall: Bool, completion: (NSError?) -> Void) {
        var error: NSError?

        audioDevice.isEnabled = false
        audioDevice.block()

        guard sessionId != -1,
            let twilioCallInvite = twilioCallInvite else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        let acceptOptions: TVOAcceptOptions = TVOAcceptOptions(callInvite: twilioCallInvite) { (builder) in
            builder.uuid = twilioCallInvite.uuid
        }
        twilioCall = twilioCallInvite.accept(with: acceptOptions, delegate: self)

        if twilioCall?.state != .connecting {
            DDLogError("☎️ - accepting incoming call failed")
            error = NSError(domain: Constants.Call.domain, code: 0, userInfo: nil)
        } else {
            DDLogInfo("☎️ - accepting incoming call succeeded")
        }

        completion(error)
    }

    func hangUp(_ sessionId: Int, completion: (NSError?) -> Void) {
        DDLogInfo("☎️ - hanging up call")
        twilioCall?.disconnect()
        call?.callState = .terminated

        audioDevice.isEnabled = true
        audioDevice.block()

        completion(nil)
    }

    func rejectCall(_ sessionId: Int, code: Int, completion: (NSError?) -> Void) {
        DDLogInfo("☎️ - rejecting call")

        twilioCallInvite?.reject()

        completion(nil)
    }

    func mute(_ sessionId: Int, mute: Bool, completion: (NSError?) -> Void) {
        var error: NSError?

        twilioCall?.isMuted = mute
        if twilioCall?.isMuted != mute {
            DDLogError("☎️ - Mute/unMute failed")
            error = NSError(domain: Constants.Call.domain, code: 0, userInfo: ["description": "Mute/unMute failed"])
        } else {
            DDLogInfo("☎️ - Mute/unMute succeeded")
        }

        completion(error)
    }

    func hold(_ sessionId: Int, completion: (NSError?) -> Void) {
        var error: NSError?

        twilioCall?.isOnHold = true

        if twilioCall?.isOnHold == false {
            DDLogError("☎️ - Holding call failed")
            error = NSError(domain: Constants.Call.domain, code: 0, userInfo: ["description": "Unholding call failed"])
        } else {
            DDLogInfo("☎️ - Holding call succeeded")
        }

        completion(error)
    }

    func unhold(_ sessionId: Int, completion: (NSError?) -> Void) {
        var error: NSError?

        twilioCall?.isOnHold = false

        if twilioCall?.isOnHold == true {
            DDLogError("☎️ - Unholding call failed")
            error = NSError(domain: Constants.Call.domain, code: 0, userInfo: ["description": "Unholding call failed"])
        } else {
            DDLogInfo("☎️ - Unholding call succeeded")
        }

        completion(error)
    }

    func createCall(to: String, hasVideo: Bool, completion: (Call?, NSError?) -> Void) {
        var error: NSError?

        audioDevice.isEnabled = false
        audioDevice.block()

        guard let accessToken = fetchAccessToken(),
            let from = credentials?.login else {
            DDLogError("☎️ - creating outgoing call failed")
            error = NSError(domain: Constants.Call.domain, code: 0, userInfo: ["description": "Call failed"])
            completion(call, error)
            return
        }

        call = Call(voipManager: voipManager)

        let connectOptions: TVOConnectOptions = TVOConnectOptions(accessToken: accessToken) { (builder) in
            builder.params = ["to": to]
        }

        twilioCall = TwilioVoice.connect(with: connectOptions, delegate: self)
        call?.caller = from
        call?.callee = to
        call?.sessionId = Int.random(in: 0...100)
        call?.callState = .initialized

        completion(call, error)
    }

    func sendDTMF(_ sessionId: Int, character: Character) {
        let characterString = String(character)
        twilioCall?.sendDigits(characterString)
    }

    func startAudio() {
        audioDevice.isEnabled = true
    }

    func stopAudio() {
    }

    func enableLocalVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
    }

    func enableRemoteVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
    }

    func toggleCameraPosition(completion: (NSError?) -> Void) {
    }
}

// MARK: - TVOCallDelegate

extension TwilioVoiceAdapter: TVOCallDelegate {

    func callDidStartRinging(_ call: TVOCall) {
        DDLogInfo("☎️ - callDidStartRinging()")

        guard let afoneCall = self.call else {
            return
        }

        afoneCall.callState = .ringing
    }

    func callDidConnect(_ call: TVOCall) {
        DDLogInfo("☎️ - callDidConnect()")

        guard let afoneCall = self.call else {
            return
        }

        if afoneCall.isIncomingCall {
            voipManager.didAnswerCall(afoneCall)
        }

        afoneCall.callState = .talking
    }

    func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
        DDLogInfo("☎️ - didDisconnectWithError(): \(error.debugDescription)")

        guard let afoneCall = self.call else {
            return
        }

        if afoneCall.callState != .talking {
            afoneCall.isMissed = true
            voipManager.gotMissedCall(afoneCall)
        }

        afoneCall.isHungUpRemotely = true
        afoneCall.callState = .terminated
        self.call = nil
        twilioCall = nil
        twilioCallInvite = nil
    }

    func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
        DDLogInfo("☎️ - didFailToConnectWithError(): \(error.localizedDescription)")
        self.call = nil
        twilioCall = nil
        twilioCallInvite = nil
    }
}

// MARK: - TVONotificationDelegate

extension TwilioVoiceAdapter: TVONotificationDelegate {
    func cancelledCallInviteReceived(_ cancelledCallInvite: TVOCancelledCallInvite) {
        DDLogInfo("☎️ - cancelledCallInviteReceived()")
        call?.callState = .terminated
        twilioCallInvite?.reject()
    }

    func callInviteReceived(_ callInvite: TVOCallInvite) {
        DDLogInfo("☎️ - callInviteReceived()")

        call = Call(voipManager: voipManager)
        call?.sessionId = Int.random(in: 0...100)
        call?.caller = callInvite.from ?? ""
        call?.callee = callInvite.to
        call?.callerDisplayName = callInvite.from
        call?.callState = .ringing
        call?.isIncomingCall = true

        twilioCallInvite = callInvite

        if let call = call {
            voipManager.gotIncomingCall(call)
        }

    }
}

// MARK: Push Registry

extension TwilioVoiceAdapter: PushPayloadObserver {
    func didUpdatePushToken(_ token: Data) {
        deviceToken = (token as NSData).description

        guard let accessToken = fetchAccessToken() else {
            DDLogError("☎️ - Failed to retrieve accessToken")
            return
        }

        TwilioVoice.register(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
            if let error = error {
                DDLogError("☎️ - An error occurred while registering: \(error.localizedDescription)")
            } else {
                DDLogInfo("☎️ - Successfully registered for VoIP push notifications.")
            }
        }
    }

    func didReceivePayload(_ payload: [AnyHashable: Any]) {
        TwilioVoice.handleNotification(payload, delegate: self)
    }

    func didInvalidatePushToken() {
        guard let accessToken = fetchAccessToken() else {
            DDLogError("☎️ - Failed to retrieve accessToken")
            return
        }

        TwilioVoice.unregister(withAccessToken: accessToken, deviceToken: deviceToken) { [weak self] (_) in
            self?.deviceToken = ""
        }
    }
}
