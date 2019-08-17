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

//swiftlint:disable file_length

import Foundation
import CocoaLumberjack
import PortSIPVoIPSDK

class PortSIPAdapter: NSObject {

    /// PortSIP SDK used by this adapter implementation.
    private let sipSDK = PortSIPSDK()

    /// The current call.
    private var call: Call?

    /// The server credentials.
    private var credentials: Credentials?

    /// Last remembered settings
    private var settings: Settings?

    /// The application’s `VoIPManager` used to interact with a concrete adapter implementation.
    private let voipManager: VoIPManager

    /// Local view required for the PortSIP SDK to render local video into.
    private var portsipLocalVideoView: PortSIPVideoRenderView?

    /// Local view required for the PortSIP SDK to render remote video into.
    private var portsipRemoteVideoView: PortSIPVideoRenderView?

    /// A dictionary with DTMF signals.
    private let dtmfDictionary: [String: Int32] = [
        "0": 0,
        "1": 1,
        "2": 2,
        "3": 3,
        "4": 4,
        "5": 5,
        "6": 6,
        "7": 7,
        "8": 8,
        "9": 9,
        "*": 10,
        "#": 11
    ]

    /// The identifier of the camera used by the PortSIP SDK (usually front / back).
    private var cameraId: Int32 = 1

    /// License
    // swiftlint:disable:next line_length
    fileprivate let license = "PORTSIP_TEST_LICENSE"

    /**
     A reference to the block to execute after the PortSIP SDK registered with a server.

     The block is stored as an instance variable, because the PortSIP SDK can actually call different delegate functions where the block should be executed.
    */
    private var registerCompletion: ((NSError?) -> Void)?

    /**
     Initializes the adapter.

    - Parameter voipManager: The application’s `VoIPManager` that can be used for call-related functionality, and which delegates to an adapter implementation.
    */
    init(voipManager: VoIPManager) {
        self.voipManager = voipManager

        super.init()
        sipSDK.delegate = self
    }

    /**
     Logs in to a server and initializes the PortSIP SDK.

     - Parameter credentials: The credentials that should be used for a login.
     - Parameter completion: The block to execute after a login.
     */
    private func login(credentials: Credentials, completion: @escaping (NSError?) -> Void) {
        self.credentials = credentials
        initializeSip(completion: completion)
    }

    /**
     Sets up codecs and other settings.

     - Parameter settings: The settings which should be used to set up codecs and other session-related options.
     */
    private func setupCodecsAndSettings(_ settings: Settings) {
        sipSDK.clearAudioCodec()
        sipSDK.clearVideoCodec()

        // For compatibility in settings we store values as `Int`. Initially we get `Int32` from the SDK, though.
        for codec in settings.codecs {
            if codec.type == .audio {
                if let value = codec.value as? Int {
                    sipSDK.addAudioCodec(AUDIOCODEC_TYPE(rawValue: Int32(value)))
                } else if let value = codec.value as? Int32 {
                    sipSDK.addAudioCodec(AUDIOCODEC_TYPE(rawValue: value))
                }
            } else if codec.type == .video {
                if let value = codec.value as? Int {
                    sipSDK.addVideoCodec(VIDEOCODEC_TYPE(rawValue: Int32(value)))
                } else if let value = codec.value as? Int32 {
                    sipSDK.addVideoCodec(VIDEOCODEC_TYPE(rawValue: value))
                }
            }
        }

        sipSDK.setVideoBitrate(Constants.Call.allSessions, bitrateKbps: Constants.Call.videoMinBitRate)
        sipSDK.setVideoFrameRate(Constants.Call.allSessions, frameRate: Constants.Call.videoMinFrameRate)
        sipSDK.setVideoResolution(Constants.Call.videoWidth, height: Constants.Call.videoHeight)
        sipSDK.enableVideoQos(true)

        sipSDK.setVideoNackStatus(true)
        if let srtpPolicy = settings.srtpOptions?.value as? UInt32 {
            sipSDK.setSrtpPolicy(SRTP_POLICY(rawValue: srtpPolicy))
        } else if let srtpPolicy = settings.srtpOptions?.value as? Int {
            sipSDK.setSrtpPolicy(SRTP_POLICY(rawValue: UInt32(srtpPolicy)))
        } else {
            sipSDK.setSrtpPolicy(SRTP_POLICY_NONE)
        }

        sipSDK.setAudioSamples(Constants.Call.audioPtime, maxPtime: Constants.Call.audioMaxPtime) // Ptime 20
    }

    /**
     Registers a server via the PortSIP SDK.

     - Parameter completion: The block to execute after the PortSIP SDK registered with a server.
     */
    func register(completion: @escaping (NSError?) -> Void) {
        registerCompletion = completion
        let status = sipSDK.registerServer(Constants.SIP.sipRegistrationRefreshSeconds, retryTimes: Constants.SIP.sipRegistrationRetry)
        if status == 0 {
            DDLogInfo("☎️ - PortSIP register SUCCESS")
        } else {
            DDLogError("☎️ - PortSIP register FAIL: \(status)")
        }
    }

    /// Unregisters the server via the PortSIP SDK.
    func unregister() {
        let status = sipSDK.unRegisterServer()
        if status == 0 {
            DDLogInfo("☎️ - PortSIP unregister SUCCESS")
        } else {
            DDLogError("☎️ - PortSIP unregister FAIL: \(status)")
        }
    }

    /// Unitializes the PortSIP SDK.
    func uninitialize() {
        unregister()
        sipSDK.removeUser()
        sipSDK.unInitialize()
    }

    /// Unitializes the PortSIP SDK while keeping the user.
    func uninitilizeKeepingUser() {
        unregister()
        sipSDK.unInitialize()
    }

    /**
     Initializes the PortSIP SDK.

     - Parameter completion: The block to execute after the PortSIP SDK was initialized.
     */
    func initializeSip(completion: @escaping (NSError?) -> Void) {
        // swiftlint:disable:previous function_body_length
        guard
            let credentials = credentials else {
                let error = NSError(domain: "PortSIPAdapter", code: 403, userInfo: ["description": "No Credentials"])
                completion(error)
                return
        }

        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first

        let transport: TRANSPORT_TYPE = {
            switch credentials.advanced.transport {
            case .udp:
                return TRANSPORT_UDP
            case .tcp:
                return TRANSPORT_TCP
            case .tls:
                return TRANSPORT_TLS
            }
        }()

        var initStatus = sipSDK.initialize(transport,
                                                localIP: Constants.SIP.localIP,
                                                localSIPPort: Int32(credentials.advanced.localPort),
                                                loglevel: PORTSIP_LOG_DEBUG,
                                                logPath: documentsDirectory,
                                                maxLine: 1,
                                                agent: Constants.userAgent,
                                                audioDeviceLayer: 0,
                                                videoDeviceLayer: 0,
                                                tlsCertificatesRootPath: "",
                                                tlsCipherList: "",
                                                verifyTLSCertificate: credentials.advanced.verifyTLS)

        initStatus = sipSDK.setLicenseKey(license)
        if initStatus == 0 {
            DDLogInfo("☎️ - PortSIP licensing SUCCESS")
        } else if initStatus == ECoreTrialVersionLicenseKey {
            DDLogInfo("☎️ - PortSIP licensing SUCCESS - trial license")
        } else {
            DDLogError("☎️ - PortSIP licensing FAIL: \(initStatus)")
        }

        initStatus = sipSDK.setUser(credentials.login,
                                         displayName: credentials.advanced.displayName ?? credentials.login,
                                         authName: credentials.advanced.authName ?? credentials.login,
                                         password: credentials.password,
                                         userDomain: "",
                                         sipServer: credentials.sipServer,
                                         sipServerPort: Int32(credentials.advanced.port),
                                         stunServer: credentials.advanced.stunServer,
                                         stunServerPort: Int32(credentials.advanced.stunPort),
                                         outboundServer: credentials.advanced.outboundServer,
                                         outboundServerPort: Int32(credentials.advanced.outboundPort))

        if initStatus == 0 {
            DDLogInfo("☎️ - PortSIP login SUCCESS")
        } else {
            DDLogError("☎️ - PortSIP login FAIL: \(initStatus)")
        }

        register(completion: completion)
    }
}

// MARK: - VoIPManagerDelegate

extension PortSIPAdapter: VoIPManagerDelegate {

    var remoteVideoView: UIView? {
        if portsipRemoteVideoView == nil {
            portsipRemoteVideoView = PortSIPVideoRenderView.init(frame: UIScreen.main.bounds)
            portsipRemoteVideoView?.initVideoRender()
        }
        return portsipRemoteVideoView
    }

    var localVideoView: UIView? {
        if portsipLocalVideoView == nil {
            portsipLocalVideoView = PortSIPVideoRenderView.init(frame: UIScreen.main.bounds)
            portsipLocalVideoView?.initVideoRender()
        }
        return portsipLocalVideoView
    }

    func reload(with settings: Settings) {
        self.settings = settings
        DispatchQueue.global(qos: .background).async {
            self.setupCodecsAndSettings(settings)
        }
    }

    var srtpOptions: [SRTP] {
        return [
            SRTP(name: "None", type: .none, value: SRTP_POLICY_NONE.rawValue),
            SRTP(name: "Prefer", type: .prefer, value: SRTP_POLICY_PREFER.rawValue),
            SRTP(name: "Force", type: .force, value: SRTP_POLICY_FORCE.rawValue)
        ]
    }

    var audioCodecs: [Codec] {
        return [
            Codec(name: "G729", type: .audio, value: AUDIOCODEC_G729.rawValue),
            Codec(name: "PCMA", type: .audio, value: AUDIOCODEC_PCMA.rawValue),
            Codec(name: "PCMU", type: .audio, value: AUDIOCODEC_PCMU.rawValue),
            Codec(name: "GSM", type: .audio, value: AUDIOCODEC_GSM.rawValue),
            Codec(name: "G722", type: .audio, value: AUDIOCODEC_G722.rawValue),
            Codec(name: "ILBC", type: .audio, value: AUDIOCODEC_ILBC.rawValue),
            Codec(name: "AMR", type: .audio, value: AUDIOCODEC_AMR.rawValue),
            Codec(name: "AMRWB", type: .audio, value: AUDIOCODEC_AMRWB.rawValue),
            Codec(name: "SPEEX", type: .audio, value: AUDIOCODEC_SPEEX.rawValue),
            Codec(name: "SPEEXWB", type: .audio, value: AUDIOCODEC_SPEEXWB.rawValue),
            Codec(name: "ISACWB", type: .audio, value: AUDIOCODEC_ISACWB.rawValue),
            Codec(name: "ISACSWB", type: .audio, value: AUDIOCODEC_ISACSWB.rawValue),
            Codec(name: "G7221", type: .audio, value: AUDIOCODEC_G7221.rawValue),
            Codec(name: "OPUS", type: .audio, value: AUDIOCODEC_OPUS.rawValue),
            Codec(name: "DTMF", type: .audio, value: AUDIOCODEC_DTMF.rawValue)
        ]
    }

    var videoCodecs: [Codec] {
        return [
            Codec(name: "I420", type: .video, value: VIDEO_CODEC_I420.rawValue),
            Codec(name: "H.263", type: .video, value: VIDEO_CODEC_H263.rawValue),
            Codec(name: "H.263 1998", type: .video, value: VIDEO_CODEC_H263_1998.rawValue),
            Codec(name: "H.264", type: .video, value: VIDEO_CODEC_H264.rawValue),
            Codec(name: "VP8", type: .video, value: VIDEO_CODEC_VP8.rawValue),
            Codec(name: "VP9", type: .video, value: VIDEO_CODEC_VP9.rawValue)
        ]
    }

    func logout(completion: (() -> Void)?) {
        uninitialize()
        completion?()
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

    func initAdapter(credentials: Credentials, completion: @escaping (NSError?) -> Void) {
        login(credentials: credentials, completion: completion)
    }

    func answerCall(_ sessionId: Int, videoCall: Bool, completion: (NSError?) -> Void) {
        var error: NSError?

        guard sessionId != -1 else {
            error = NSError(domain: Constants.Call.domain, code: Constants.Call.ErrorCode.sessionIdMissing.rawValue, userInfo: nil)
            completion(error)
            return
        }

        let status = sipSDK.answerCall(sessionId, videoCall: videoCall)
        if status > 0 {
            DDLogError("☎️ - accepting incoming call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: nil)
        } else {
            DDLogInfo("☎️ - accepting incoming call succeeded \(status)")
        }

        completion(error)
    }

    func hangUp(_ sessionId: Int, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.hangUp(sessionId)
        call?.callState = .terminated
        if status > 0 {
            DDLogError("☎️ - hanging up call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: ["description": "Hanup failed"])
        } else {
            DDLogInfo("☎️ - hanging up call succeeded \(status)")
        }

        completion(error)
    }

    func rejectCall(_ sessionId: Int, code: Int, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.rejectCall(sessionId, code: Int32(code))
        if status != 0 {
            DDLogError("☎️ - rejecting call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: ["description": "Hanup failed"])
        } else {
            DDLogInfo("☎️ - rejecting call succeeded \(status)")
        }

        completion(error)
    }

    func mute(_ sessionId: Int, mute: Bool, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.muteSession(sessionId, muteIncomingAudio: false, muteOutgoingAudio: mute, muteIncomingVideo: false, muteOutgoingVideo: mute)
        if status != 0 {
            DDLogError("☎️ - Mute/unMute failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: ["description": "Mute/unMute failed"])
        } else {
            DDLogInfo("☎️ - Mute/unMute succeeded \(status)")
        }

        completion(error)
    }

    func hold(_ sessionId: Int, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.hold(sessionId)
        if status != 0 {
            DDLogError("☎️ - Holding call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: ["description": "Holding call failed"])
        } else {
            DDLogInfo("☎️ - Holding call succeeded \(status)")
        }

        completion(error)
    }

    func unhold(_ sessionId: Int, completion: (NSError?) -> Void) {
        var error: NSError?
        let status = sipSDK.unHold(sessionId)
        if status != 0 {
            DDLogError("☎️ - Unholding call failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: ["description": "Unholding call failed"])
        } else {
            DDLogInfo("☎️ - Unholding call succeeded \(status)")
        }

        completion(error)
    }

    func createCall(to: String, hasVideo: Bool, completion: (Call?, NSError?) -> Void) {
        var error: NSError?

        call = Call(voipManager: voipManager)

        let status = sipSDK.call(to, sendSdp: true, videoCall: hasVideo)
        if status <= 0 {
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

    func sendDTMF(_ sessionId: Int, character: Character) {
        let characterString = String(character)
        guard let code = dtmfDictionary[characterString] else {
            return
        }

        sipSDK.sendDtmf(sessionId, dtmfMethod: DTMF_RFC2833, code: code, dtmfDration: 160, playDtmfTone: false)
    }

    func startAudio() {
        sipSDK.startAudio()
    }

    func stopAudio() {
        sipSDK.stopAudio()
    }

    func enableLocalVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
        guard let sessionId = call?.sessionId else {
            completion?(false)
            return
        }

        if enable {
            guard let portsipLocalVideoView = portsipLocalVideoView else {
                return
            }

            sipSDK.setVideoDeviceId(cameraId)
            sipSDK.setLocalVideoWindow(portsipLocalVideoView)
            sipSDK.displayLocalVideo(enable)
        } else {
            sipSDK.displayLocalVideo(false)
            sipSDK.setLocalVideoWindow(nil)
        }

        sipSDK.sendVideo(sessionId, sendState: enable)
        sipSDK.updateCall(sessionId, enableAudio: true, enableVideo: enable)

        call?.isSendingVideo = enable

        completion?(true)
    }

    func enableRemoteVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
        guard let sessionId = call?.sessionId else {
            completion?(false)
            return
        }

        if enable {
            guard let portsipRemoteVideoView = portsipRemoteVideoView else {
                return
            }

            sipSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: nil)
            sipSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: portsipRemoteVideoView)
        } else {
            sipSDK.setRemoteVideoWindow(sessionId, remoteVideoWindow: nil)
        }

        completion?(true)
    }

    func toggleCameraPosition(completion: (NSError?) -> Void) {
        var error: NSError?
        cameraId = cameraId == 1 ? 0 : 1
        let status = sipSDK.setVideoDeviceId(cameraId)
        if status == 0 {
            DDLogInfo("☎️ - Switching camera succeeded \(status)")
        } else {
            DDLogError("☎️ - Switching camera failed \(status)")
            error = NSError(domain: Constants.Call.domain, code: Int(status), userInfo: ["description": "Switching camera failed"])
        }

        completion(error)
    }
}

// MARK: - PortSIPEventDelegate

// swiftlint:disable function_parameter_count line_length

extension PortSIPAdapter: PortSIPEventDelegate {

    func onRegisterSuccess(_ statusText: UnsafeMutablePointer<Int8>!, statusCode: Int32, sipMessage: UnsafeMutablePointer<Int8>!) {
        registerCompletion?(nil)
    }

    func onRegisterFailure(_ statusText: UnsafeMutablePointer<Int8>!, statusCode: Int32, sipMessage: UnsafeMutablePointer<Int8>!) {
        uninitialize()
        let error = NSError(domain: "PortSIPAdapter", code: Int(statusCode), userInfo: ["description": "Wrong Credentials"])
        registerCompletion?(error)
    }

    func onInviteIncoming(_ sessionId: Int, callerDisplayName: UnsafeMutablePointer<Int8>!, caller: UnsafeMutablePointer<Int8>!, calleeDisplayName: UnsafeMutablePointer<Int8>!, callee: UnsafeMutablePointer<Int8>!, audioCodecs: UnsafeMutablePointer<Int8>!, videoCodecs: UnsafeMutablePointer<Int8>!, existsAudio: Bool, existsVideo: Bool, sipMessage: UnsafeMutablePointer<Int8>!) {

        DDLogInfo("☎️ - onInviteIncoming() sessionId: \(sessionId)")

        let callerName = String(validatingUTF8: callerDisplayName)
        let caller = String(validatingUTF8: caller)
        let callee = String(validatingUTF8: callee)

        call = Call(voipManager: voipManager)
        call?.sessionId = sessionId
        call?.caller = SipUser(string: caller).stringRepresentation
        call?.callee = SipUser(string: callee).stringRepresentation
        call?.callerDisplayName = callerName
        call?.existsAudio = existsAudio
        call?.isReceivingVideo = existsVideo
        call?.callState = .ringing
        call?.isIncomingCall = true

        if let call = call {
            voipManager.gotIncomingCall(call)
        }
    }

    func onInviteTrying(_ sessionId: Int) {
        DDLogInfo("☎️ - onInviteTrying() sessionId: \(sessionId)")
        call?.callState = .dialing
    }

    func onInviteSessionProgress(_ sessionId: Int, audioCodecs: UnsafeMutablePointer<Int8>!, videoCodecs: UnsafeMutablePointer<Int8>!, existsEarlyMedia: Bool, existsAudio: Bool, existsVideo: Bool, sipMessage: UnsafeMutablePointer<Int8>!) {
        DDLogInfo("☎️ - onInviteSessionProgress() sessionId: \(sessionId)")
    }

    func onInviteRinging(_ sessionId: Int, statusText: UnsafeMutablePointer<Int8>!, statusCode: Int32, sipMessage: UnsafeMutablePointer<Int8>!) {
        DDLogInfo("☎️ - onInviteRinging() sessionId: \(sessionId)")

        // If status code is 180 - onnet call, we need to play a ringback tone locally.
        // For offnet calls the code will be 183, or onInviteRinging will not be called at all ideally.
        // For now we ignore the status code and play local sound only when onInviteRinging was called.
        // For more details: https://tools.ietf.org/html/rfc3960
        call?.callState = .ringing
    }

    func onInviteAnswered(_ sessionId: Int, callerDisplayName: UnsafeMutablePointer<Int8>!, caller: UnsafeMutablePointer<Int8>!, calleeDisplayName: UnsafeMutablePointer<Int8>!, callee: UnsafeMutablePointer<Int8>!, audioCodecs: UnsafeMutablePointer<Int8>!, videoCodecs: UnsafeMutablePointer<Int8>!, existsAudio: Bool, existsVideo: Bool, sipMessage: UnsafeMutablePointer<Int8>!) {
        DDLogInfo("☎️ - onInviteAnswered() sessionId: \(sessionId)")
    }

    func onInviteFailure(_ sessionId: Int, reason: UnsafeMutablePointer<Int8>!, code: Int32, sipMessage: UnsafeMutablePointer<Int8>!) {
        if let call = call {
            call.isHungUpRemotely = true
            call.callState = .terminated
        }
    }

    func onInviteUpdated(_ sessionId: Int, audioCodecs: UnsafeMutablePointer<Int8>!, videoCodecs: UnsafeMutablePointer<Int8>!, existsAudio: Bool, existsVideo: Bool, sipMessage: UnsafeMutablePointer<Int8>!) {
        DDLogInfo("☎️ - onInviteUpdated() sessionId: \(sessionId)")
        guard let call = call,
            call.sessionId == sessionId else {
            return
        }

        if call.isReceivingVideo != existsVideo {
            call.isReceivingVideo = existsVideo
            if call.isSendingVideo {
                sipSDK.updateCall(sessionId, enableAudio: true, enableVideo: call.isSendingVideo)
            }
        }
    }

    func onInviteConnected(_ sessionId: Int) {
        DDLogInfo("☎️ - onInviteConnected() sessionId: \(sessionId)")

        if let call = call {
            if call.isIncomingCall {
                voipManager.didAnswerCall(call)
            }
        }

        call?.callState = .talking
    }

    func onInviteBeginingForward(_ forwardTo: UnsafeMutablePointer<Int8>!) {
    }

    func onInviteClosed(_ sessionId: Int) {
        DDLogInfo("☎️ - onInviteClosed() sessionId: \(sessionId)")
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

    func onDialogStateUpdated(_ BLFMonitoredUri: UnsafeMutablePointer<Int8>!, blfDialogState BLFDialogState: UnsafeMutablePointer<Int8>!, blfDialogId BLFDialogId: UnsafeMutablePointer<Int8>!, blfDialogDirection BLFDialogDirection: UnsafeMutablePointer<Int8>!) {
    }

    func onRemoteHold(_ sessionId: Int) {
        call?.callState = .holding
    }

    func onRemoteUnHold(_ sessionId: Int, audioCodecs: UnsafeMutablePointer<Int8>!, videoCodecs: UnsafeMutablePointer<Int8>!, existsAudio: Bool, existsVideo: Bool) {
        call?.callState = .talking
    }

    func onReceivedRefer(_ sessionId: Int, referId: Int, to: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, referSipMessage: UnsafeMutablePointer<Int8>!) {
    }

    func onReferAccepted(_ sessionId: Int) {
    }

    func onReferRejected(_ sessionId: Int, reason: UnsafeMutablePointer<Int8>!, code: Int32) {
    }

    func onTransferTrying(_ sessionId: Int) {
    }

    func onTransferRinging(_ sessionId: Int) {
    }

    func onACTVTransferSuccess(_ sessionId: Int) {
    }

    func onACTVTransferFailure(_ sessionId: Int, reason: UnsafeMutablePointer<Int8>!, code: Int32) {
    }

    func onReceivedSignaling(_ sessionId: Int, message: UnsafeMutablePointer<Int8>!) {
    }

    func onSendingSignaling(_ sessionId: Int, message: UnsafeMutablePointer<Int8>!) {
    }

    func onWaitingVoiceMessage(_ messageAccount: UnsafeMutablePointer<Int8>!, urgentNewMessageCount: Int32, urgentOldMessageCount: Int32, newMessageCount: Int32, oldMessageCount: Int32) {
    }

    func onWaitingFaxMessage(_ messageAccount: UnsafeMutablePointer<Int8>!, urgentNewMessageCount: Int32, urgentOldMessageCount: Int32, newMessageCount: Int32, oldMessageCount: Int32) {
    }

    func onRecvDtmfTone(_ sessionId: Int, tone: Int32) {
    }

    func onRecvOptions(_ optionsMessage: UnsafeMutablePointer<Int8>!) {
    }

    func onRecvInfo(_ infoMessage: UnsafeMutablePointer<Int8>!) {
    }

    func onRecvNotifyOfSubscription(_ subscribeId: Int, notifyMessage: UnsafeMutablePointer<Int8>!, messageData: UnsafeMutablePointer<UInt8>!, messageDataLength: Int32) {
    }

    func onPresenceRecvSubscribe(_ subscribeId: Int, fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, subject: UnsafeMutablePointer<Int8>!) {
    }

    func onPresenceOnline(_ fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, stateText: UnsafeMutablePointer<Int8>!) {
    }

    func onPresenceOffline(_ fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!) {
    }

    func onRecvMessage(_ sessionId: Int, mimeType: UnsafeMutablePointer<Int8>!, subMimeType: UnsafeMutablePointer<Int8>!, messageData: UnsafeMutablePointer<UInt8>!, messageDataLength: Int32) {
    }

    func onRecvOutOfDialogMessage(_ fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, toDisplayName: UnsafeMutablePointer<Int8>!, to: UnsafeMutablePointer<Int8>!, mimeType: UnsafeMutablePointer<Int8>!, subMimeType: UnsafeMutablePointer<Int8>!, messageData: UnsafeMutablePointer<UInt8>!, messageDataLength: Int32, sipMessage: UnsafeMutablePointer<Int8>!) {
    }

    func onSendMessageSuccess(_ sessionId: Int, messageId: Int) {
    }

    func onSendMessageFailure(_ sessionId: Int, messageId: Int, reason: UnsafeMutablePointer<Int8>!, code: Int32) {
    }

    func onSendOutOfDialogMessageSuccess(_ messageId: Int, fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, toDisplayName: UnsafeMutablePointer<Int8>!, to: UnsafeMutablePointer<Int8>!) {
    }

    func onSendOutOfDialogMessageFailure(_ messageId: Int, fromDisplayName: UnsafeMutablePointer<Int8>!, from: UnsafeMutablePointer<Int8>!, toDisplayName: UnsafeMutablePointer<Int8>!, to: UnsafeMutablePointer<Int8>!, reason: UnsafeMutablePointer<Int8>!, code: Int32) {
    }

    func onSubscriptionFailure(_ subscribeId: Int, statusCode: Int32) {
    }

    func onSubscriptionTerminated(_ subscribeId: Int) {
    }

    func onPlayAudioFileFinished(_ sessionId: Int, fileName: UnsafeMutablePointer<Int8>!) {
    }

    func onPlayVideoFileFinished(_ sessionId: Int) {
    }

    func onReceivedRTPPacket(_ sessionId: Int, isAudio: Bool, rtpPacket RTPPacket: UnsafeMutablePointer<UInt8>!, packetSize: Int32) {
    }

    func onSendingRTPPacket(_ sessionId: Int, isAudio: Bool, rtpPacket RTPPacket: UnsafeMutablePointer<UInt8>!, packetSize: Int32) {
    }

    func onAudioRawCallback(_ sessionId: Int, audioCallbackMode: Int32, data: UnsafeMutablePointer<UInt8>!, dataLength: Int32, samplingFreqHz: Int32) {
    }

    func onVideoRawCallback(_ sessionId: Int, videoCallbackMode: Int32, width: Int32, height: Int32, data: UnsafeMutablePointer<UInt8>!, dataLength: Int32) -> Int32 {
        return 0
    }
}
