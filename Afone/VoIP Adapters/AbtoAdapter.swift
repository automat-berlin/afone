//
// Afone
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

//swiftlint:disable file_length

import Foundation
import CocoaLumberjack

class AbtoAdapter: NSObject {

    private let sipSDK = AbtoPhoneInterface()
    private let voipManager: VoIPManager
    private var call: Call?
    private var credentials: Credentials?
    private var settings: Settings?
    private var registerCompletion: ((NSError?) -> Void)?
    private var isFrontCameraEnabled: Bool = true
    private var abtoLocalVideoView: UIImageView?
    private var abtoRemoteVideoView: UIImageView?

    init(voipManager: VoIPManager) {
        self.voipManager = voipManager

        super.init()
        self.sipSDK.initialize(self)
    }

    private func login(credentials: Credentials, completion: @escaping (NSError?) -> Void) {
        self.credentials = credentials
        initializeSip(completion: completion)
    }

    private func setupCodecsAndSettings(_ settings: Settings) {
        sipSDK.config().setCodecPriority(.none, priority: 0)

        // Disable all codecs
        let allCodecs = audioCodecs + videoCodecs
        for codec in allCodecs {
            if let intValue = codec.value as? Int,
                let nativeCodec = PhoneAudioVideoCodec(rawValue: intValue) {
                sipSDK.config().setCodecPriority(nativeCodec, priority: 0)
            }
        }

        // Enable selected codecs
        for codec in settings.codecs {
            if let value = codec.value as? Int,
                let nativeCodec = PhoneAudioVideoCodec(rawValue: value) {
                sipSDK.config().setCodecPriority(nativeCodec, priority: value)
            }
        }

        // Enable SRTP
        if let srtpPolicy = settings.srtpOptions?.value as? Int {
            if srtpPolicy == 1 {
                sipSDK.config().enableSrtp = true
            } else if srtpPolicy == 2 {
                sipSDK.config().enableZrtp = true
            } else {
                sipSDK.config().enableSrtp = false
                sipSDK.config().enableZrtp = false
            }
        } else {
            sipSDK.config().enableSrtp = false
            sipSDK.config().enableZrtp = false
        }
    }

    func register(completion: @escaping (NSError?) -> Void) {
        registerCompletion = completion
        let status = sipSDK.finalizeConfiguration()
        if status {
            DDLogInfo("☎️ - Abto register SUCCESS")
        } else {
            DDLogError("☎️ - Abto register FAIL: \(status)")
        }
    }

    func unregister() {
        let status = sipSDK.unregister()
        if status {
            DDLogInfo("☎️ - Abto unregister SUCCESS")
        } else {
            DDLogError("☎️ - Abto unregister FAIL: \(status)")
        }
    }

    func uninitialize() {
        unregister()
        sipSDK.config().regUser = nil
        sipSDK.config().regDomain = nil
        sipSDK.config().regPassword = nil
    }

    func uninitilizeKeepingUser() {
        unregister()
    }

    func initializeSip(completion: @escaping (NSError?) -> Void) {
        guard
            let credentials = credentials else {
                let error = NSError(domain: "AbtoAdapter", code: 403, userInfo: ["description": "No Credentials"])
                completion(error)
                return
        }

        let transport: PhoneSignalingTransport = {
            switch credentials.advanced.transport {
            case .udp:
                return .udp
            case .tcp:
                return .tcp
            case .tls:
                return .tls
            }
        }()

        sipSDK.config().regUser = credentials.login
        sipSDK.config().regDomain = credentials.sipServer
        sipSDK.config().regPassword = credentials.password
        sipSDK.config().regAuthId = credentials.advanced.authName ?? credentials.login
        sipSDK.config().displayName = credentials.advanced.displayName ?? credentials.login
        sipSDK.config().registerTimeout = Constants.SIP.sipRegistrationRefreshSeconds
        sipSDK.config().regExpirationTime = Constants.SIP.sipRegistrationRefreshSeconds
        sipSDK.config().localPort = Int32(credentials.advanced.localPort)
        sipSDK.config().localIp = Constants.SIP.localIP
        sipSDK.config().enableTLSVerifyServer = credentials.advanced.verifyTLS
        sipSDK.config().signalingTransport = transport
        sipSDK.config().proxy = credentials.sipServer
        if let stunServer = credentials.advanced.stunServer {
            sipSDK.config().enableStun = true
            sipSDK.config().stun = "\(stunServer):\(credentials.advanced.stunPort)"
        } else {
            sipSDK.config().enableStun = false
        }
        sipSDK.config().ua = Constants.userAgent

        register(completion: completion)
    }
}

extension AbtoAdapter: VoIPManagerDelegate {
    func answerCall(_ sessionId: Int, videoCall: Bool, completion: (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        let status = sipSDK.answerCall(sessionId, status: 200, withVideo: videoCall)
        if !status {
            DDLogError("☎️ - accepting incoming call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: 500, userInfo: nil)
        } else {
            DDLogInfo("☎️ - accepting incoming call succeeded \(status)")
        }

        completion(error)
    }

    func hangUp(_ sessionId: Int, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.hangUpCall(sessionId, status: 200)
        call?.callState = .terminated
        if !status {
            DDLogError("☎️ - hanging up call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: 401, userInfo: ["description": "Hanup failed"])
        } else {
            DDLogInfo("☎️ - hanging up call succeeded \(status)")
        }

        completion(error)
    }

    func hold(_ sessionId: Int, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.holdRetrieveCall(sessionId)
        if !status {
            DDLogError("☎️ - Holding call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: 401, userInfo: ["description": "Holding call failed"])
        } else {
            DDLogInfo("☎️ - Holding call succeeded \(status)")
        }

        completion(error)
    }

    func unhold(_ sessionId: Int, completion: (NSError?) -> Void) {
        hold(sessionId, completion: completion)
    }

    func mute(_ sessionId: Int, mute: Bool, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.muteMicrophone(sessionId, on: mute)
        if !status {
            DDLogError("☎️ - Mute/unMute failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: 401, userInfo: ["description": "Mute/unMute failed"])
        } else {
            DDLogInfo("☎️ - Mute/unMute succeeded \(status)")
        }

        completion(error)
    }

    func rejectCall(_ sessionId: Int, code: Int, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.hangUpCall(sessionId, status: Int32(Constants.Call.callBusyCode))
        if !status {
            DDLogError("☎️ - rejecting call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.callBusyCode, userInfo: ["description": "Hanup failed"])
        } else {
            DDLogInfo("☎️ - rejecting call succeeded \(status)")
        }

        completion(error)
    }

    func sendDTMF(_ sessionId: Int, character: Character) {
        let characterString = String(character)
        if let uniCharValue = characterString.utf16.first {
            sipSDK.sendTone(sessionId, tone: uniCharValue)
        }
    }

    func createCall(to: String, hasVideo: Bool, completion: (Call?, NSError?) -> Void) {
        var error: NSError?

        call = Call(voipManager: voipManager)

        let status = sipSDK.startCall(to, withVideo: hasVideo)
        if status < 0 {
            call = nil
            DDLogError("☎️ - creating outgoing call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: ["description": "Call failed"])
        } else {
            call?.caller = ""
            call?.callee = to
            call?.sessionId = status
            call?.existsAudio = true
            call?.isSendingVideo = hasVideo
            call?.callState = .initialized
        }

        completion(call, error)
    }

    func initAdapter(credentials: Credentials, completion: @escaping (NSError?) -> Void) {
        login(credentials: credentials, completion: completion)
    }

    func didEnterBackground() {
        uninitilizeKeepingUser()
    }

    func willEnterForeground() {
        initializeSip { [weak self] _ in
            if let settings = self?.settings {
                self?.reload(with: settings)
            }
        }
    }

    func logout(completion: (() -> Void)?) {
        uninitialize()
        completion?()
    }

    func reload(with settings: Settings) {
        self.settings = settings
        DispatchQueue.global(qos: .background).async {
            self.setupCodecsAndSettings(settings)
        }
    }

    func startAudio() {
        sipSDK.activateAudio()
    }

    func stopAudio() {
        sipSDK.deactivateAudio()
    }

    func enableLocalVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
        guard let sessionId = call?.sessionId else {
            completion?(false)
            return
        }

        if enable {
            guard let abtoLocalVideoView = abtoLocalVideoView else {
                return
            }

            sipSDK.setLocalView(abtoLocalVideoView)
        } else {
            sipSDK.setLocalView(nil)
        }

        sipSDK.updateCall(sessionId, mediaWithVideo: enable)

        call?.isSendingVideo = enable

        completion?(true)

    }

    func enableRemoteVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
//        guard let sessionId = call?.sessionId else {
//            completion?(false)
//            return
//        }

        if enable {
            guard let abtoRemoteVideoView = abtoRemoteVideoView else {
                return
            }

            sipSDK.setRemoteView(abtoRemoteVideoView)
        } else {
            sipSDK.setRemoteView(nil)
        }

        completion?(true)
    }

    func toggleCameraPosition(completion: (NSError?) -> Void) {
        var error: NSError?

        guard let sessionId = call?.sessionId else {
            error = NSError(domain: Constants.Call.domain, code: 401, userInfo: ["description": "Switching camera: failed to get sessionId"])
            completion(error)
            return
        }

        isFrontCameraEnabled.toggle()
        let status = sipSDK.switchCamera(toFront: sessionId, on: isFrontCameraEnabled)
        if status {
            DDLogInfo("☎️ - Switching camera succeeded \(status)")
        } else {
            DDLogError("☎️ - Switching camera failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: 401, userInfo: ["description": "Switching camera failed"])
        }

        completion(error)
    }

    var audioCodecs: [Codec] {
        return [
            Codec(name: "GSM", type: .audio, value: PhoneAudioVideoCodec.gsm.rawValue),
            Codec(name: "PCMA", type: .audio, value: PhoneAudioVideoCodec.pcma.rawValue),
            Codec(name: "PCMU", type: .audio, value: PhoneAudioVideoCodec.pcmu.rawValue),
            Codec(name: "ILBC", type: .audio, value: PhoneAudioVideoCodec.ilbc.rawValue),
            Codec(name: "SPEEXWB", type: .audio, value: PhoneAudioVideoCodec.speex.rawValue),
            Codec(name: "G729ab", type: .audio, value: PhoneAudioVideoCodec.g729ab.rawValue),
            Codec(name: "G723", type: .audio, value: PhoneAudioVideoCodec.G723.rawValue),
            Codec(name: "G722", type: .audio, value: PhoneAudioVideoCodec.G722.rawValue),
            Codec(name: "G7221", type: .audio, value: PhoneAudioVideoCodec.G722_1.rawValue),
            Codec(name: "SILK", type: .audio, value: PhoneAudioVideoCodec.silk.rawValue),
            Codec(name: "OPUS", type: .audio, value: PhoneAudioVideoCodec.opus.rawValue)
        ]
    }

    var videoCodecs: [Codec] {
        return [
            Codec(name: "H263", type: .video, value: PhoneAudioVideoCodec.h263p.rawValue),
            Codec(name: "H264", type: .video, value: PhoneAudioVideoCodec.h264Bp10.rawValue),
            Codec(name: "VP8", type: .video, value: PhoneAudioVideoCodec.vp8.rawValue)
        ]
    }

    var srtpOptions: [SRTP] {
        return [
            SRTP(name: "None", type: .none, value: 0),
            SRTP(name: "SRTP", type: .prefer, value: 1),
            SRTP(name: "ZRTP", type: .force, value: 2)
        ]
    }

    var localVideoView: UIView? {
        if abtoLocalVideoView == nil {
            abtoLocalVideoView = UIImageView(frame: UIScreen.main.bounds)
        }

        return abtoLocalVideoView
    }

    var remoteVideoView: UIView? {
        if abtoRemoteVideoView == nil {
            abtoRemoteVideoView = UIImageView(frame: UIScreen.main.bounds)
        }

        return abtoRemoteVideoView
    }
}

extension AbtoAdapter: AbtoPhoneInterfaceObserver {
    func onRegistered(_ accId: Int) {
        registerCompletion?(nil)
    }

    func onRegistrationFailed(_ accId: Int, statusCode: Int32, statusText: String) {
        uninitialize()
        let error = NSError(domain: "AbtoAdapter", code: Int(statusCode), userInfo: ["description": statusText])
        registerCompletion?(error)
    }

    func onUnRegistered(_ accId: Int) {

    }

    func onRemoteAlerting(_ accId: Int, statusCode: Int32) {

    }

    func onIncomingCall(_ callId: Int, remoteContact: String) {
        DDLogInfo("☎️ - onIncomingCall() sessionId: \(callId)")

        let caller = SipUser(string: remoteContact).stringRepresentation

        call = Call(voipManager: voipManager)
        call?.sessionId = callId
        call?.caller = caller
        call?.callerDisplayName = caller
        call?.existsAudio = true
        call?.callState = .ringing
        call?.isIncomingCall = true

        if let call = call {
            voipManager.gotIncomingCall(call)
        }

    }

    func onCallConnected(_ callId: Int, remoteContact: String) {
        DDLogInfo("☎️ - onCallConnected() sessionId: \(callId)")

        if let call = call {
            if call.isIncomingCall {
                voipManager.didAnswerCall(call)
            }
        }

        call?.callState = .talking
    }

    func onCallDisconnected(_ callId: Int, remoteContact: String, statusCode: Int, message: String) {
        DDLogInfo("☎️ - onCallDisconnected() sessionId: \(callId)")
        if call?.callState != .talking {
            call?.isMissed = true
            if let call = call {
                voipManager.gotMissedCall(call)
            }
        }

        call?.isHungUpRemotely = true
        call?.callState = .terminated
        call = nil
    }

    func onCallAlerting(_ callId: Int, statusCode: Int32) {

    }

    func onCallHeld(_ callId: Int, state: Bool) {
        if state {
            call?.callState = .holding
        } else {
            call?.callState = .talking
        }
    }

    func onToneReceived(_ callId: Int, tone: Int) {

    }

    func onTextMessageReceived(_ from: String, to: String, body: String) {

    }

    func onTextMessageStatus(_ address: String, reason: String, status: Bool) {

    }

    func onPresenceChanged(_ uri: String, status: PhoneBuddyStatus, note: String) {

    }

    func onTransferStatus(_ callId: Int, statusCode: Int32, message: String) {

    }
}
