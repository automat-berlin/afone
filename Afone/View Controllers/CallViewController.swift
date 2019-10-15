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

class CallViewController: PreviewViewController {

    @IBOutlet private weak var callView: CallView!
    @IBOutlet private weak var localVideoView: UIView!
    @IBOutlet private weak var remoteVideoView: UIView!

    private var soundManager = SoundManager()

    var call: Call? {
        didSet {
            setupCall()
        }
    }

    private func setupCall() {
        call?.addObserver(self)
        call?.durationDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let supportsVideo = call?.supportsVideo else {
            return
        }

        callView.delegate = self
        callView.call = call
        // disable video, speaker, hold and switch button until we have a connected audio call
        // only when starting a call
        if call?.isIncomingCall == false {
            callView.setCallControlButtonsEnabled(false)
        }

        callView.setVideoButtonsHidden(!supportsVideo)

        dynamicsView = localVideoView
        localVideoView.isHidden = true
        localVideoView.layer.cornerRadius = 8
        localVideoView.clipsToBounds = true
        localVideoView.backgroundColor = .black
        localVideoView.layer.borderWidth = 4
        localVideoView.layer.borderColor = UIColor.white.cgColor
        let height: CGFloat = 150.0
        let width = UIScreen.main.bounds.width / UIScreen.main.bounds.height * height
        localVideoView.frame = CGRect(x: localVideoView.frame.origin.x, y: localVideoView.frame.origin.y, width: width, height: height)

        dependencyProvider.voipManager.videoDelegate = self
        dependencyProvider.callKitManager.audioStateDelegate = self

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(showCallViewAction))
        view.addGestureRecognizer(recognizer)

        remoteVideoView.isHidden = true

        if let localVideoAdapterView = dependencyProvider.voipManager.localVideoView {
            localVideoView.addSubview(localVideoAdapterView)
            localVideoAdapterView.fillInSuperview()
        }

        if let remoteVideoAdapterView = dependencyProvider.voipManager.remoteVideoView {
            remoteVideoView.addSubview(remoteVideoAdapterView)
            remoteVideoAdapterView.fillInSuperview()
        }

        setupCall()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIApplication.shared.isIdleTimerDisabled = true

        if let call = call {
            call.isIncomingCall ? enableRemoteVideo(call.isReceivingVideo) : enableLocalVideo(call.isSendingVideo)

            call.isSendingVideo = call.isSendingVideo == true
        }
    }

    private func dismissCall() {
        UIApplication.shared.isIdleTimerDisabled = false

        enableRemoteVideo(false)
        enableLocalVideo(false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    private func enableLocalVideo(_ enable: Bool) {
        guard call?.supportsVideo == true else {
            return
        }

        if enable {
            hideCallView()
            isLoudSpeakerOn(true)
            dependencyProvider.voipManager.enableLocalVideo(true) { [weak self] (success) in
                if success {
                    DispatchQueue.main.async {
                        self?.localVideoView.isHidden = false
                    }
                }
            }
        } else {
            isLoudSpeakerOn(false)
            if let call = call,
                !call.isReceivingVideo {
                showCallView()
            }
            dependencyProvider.voipManager.enableLocalVideo(false) { [weak self] (success) in
                if success {
                    DispatchQueue.main.async {
                        self?.localVideoView.isHidden = true
                    }
                }
            }
        }
    }

    private func enableRemoteVideo(_ enable: Bool) {
        guard call?.supportsVideo == true else {
            return
        }

        if enable {
            hideCallView()
            dependencyProvider.voipManager.enableRemoteVideo(true) { [weak self] (success) in
                if success {
                    DispatchQueue.main.async {
                        self?.remoteVideoView.isHidden = false
                    }
                }
            }
        } else {
            showCallView()
            dependencyProvider.voipManager.enableRemoteVideo(false) { [weak self] (success) in
                if success {
                    DispatchQueue.main.async {
                        self?.remoteVideoView.isHidden = true
                    }
                }
            }
        }
    }
}

extension CallViewController {

    private func callView(hide: Bool, animated: Bool, animationDuration: TimeInterval) {
        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.callView.alpha = hide ? 0.0 : 1.0
            }
        } else {
            callView.alpha = hide ? 0.0 : 1.0
        }
    }

    @objc private func hideCallView() {
        callView(hide: true, animated: true, animationDuration: 0.15)
    }

    private func showCallView() {
        cancelHideCallView()
        callView(hide: false, animated: true, animationDuration: 0.15)
    }

    private func cancelHideCallView() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideCallView), object: nil)
    }

    @objc private func showCallViewAction() {
        cancelHideCallView()
        showCallView()

        perform(#selector(hideCallView), with: nil, afterDelay: 5)
    }
}

extension CallViewController {
    private func isLoudSpeakerOn(_ enabled: Bool) {
        if enabled {
            AudioSessionManager.routeAudioToSpeaker { [weak self] (succeeded) in
                DispatchQueue.main.async {
                    self?.call?.isOnSpeaker = succeeded
                    self?.callView.selectSpeaker = succeeded
                }
            }
        } else {
            AudioSessionManager.routeAudioToReceiver { [weak self] (succeeded) in
                DispatchQueue.main.async {
                    self?.call?.isOnSpeaker = !succeeded
                    self?.callView.selectSpeaker = !succeeded
                }
            }
        }
    }
}

extension CallViewController: CallViewDelegate {
    func callViewDidToggleMute(button: UIButton?) {
        guard let isMute = call?.isMute else {
            return
        }

        dependencyProvider.callKitManager.triggerMute(!isMute) { (error) in
            if error == nil {
                DispatchQueue.main.async {
                    button?.isSelected = !isMute
                }
            }
        }
    }

    func callViewDidToggleHold(button: UIButton?) {
        guard let isOnHold = call?.isOnHold else {
            return
        }

        dependencyProvider.callKitManager.triggerHold(!isOnHold) { (error) in
            if error == nil {
                DispatchQueue.main.async {
                    button?.isSelected = !isOnHold
                }
            }
        }
    }

    func callViewDidToggleLoudspeaker(button: UIButton?) {
        guard let call = call else {
            return
        }
        isLoudSpeakerOn(!call.isOnSpeaker)
    }

    func callViewDidToggleVideo(button: UIButton?) {
        guard let call = call else {
            return
        }

        enableLocalVideo(!call.isSendingVideo)
    }

    func callViewDidToggleCameraPosition(button: UIButton?) {
        dependencyProvider.voipManager.toggleCameraPosition { (error) in
            if error != nil {

            }
        }
    }

    func callViewDidPressDTMF(character: Character) {
        call?.sendDTMF(character: character)
    }

    func callViewDidHangupWithButton(button: UIButton?) {
        dependencyProvider.callKitManager.requestEndCall { [weak self] (_) in
            DispatchQueue.main.async {
                self?.dismissCall()
            }
        }
    }

    func callViewShouldUpdateSendingVideoView(view: UIView?) {

    }

    func callViewShouldUpdateReceivingVideoView(view: UIView?) {

    }

    func callViewDidHideInCallNumpadView() {

    }

    func callViewDidTapEmptySpace() {
        showCallViewAction()
    }
}

extension CallViewController: CallDelegate {
    func stateChanged(_ callState: Call.CallState, for call: Call) {
        switch callState {
        case .terminated:
            soundManager.stop()
            callViewDidHangupWithButton(button: nil)
        case .talking:
            soundManager.stop()
            callView.setHoldButtonEnabled(true)
            DispatchQueue.main.async {
                self.callView.setCallControlButtonsEnabled(true)
            }
        case .ringing:
            soundManager.play(withSoundFileName: Constants.Sound.ringbackFileName, inLoop: true)
        case .holding:
            callView.setHoldButtonEnabled(false)
            soundManager.play(withSoundFileName: Constants.Sound.elevatorMusicFileName, inLoop: true)
            if call.isOnSpeaker {
                AudioSessionManager.routeAudioToSpeaker { (_) in
                }
            }
        default:
            break
        }
    }

    func call(_ call: Call, isReceivingVideo: Bool) {
        enableRemoteVideo(isReceivingVideo)
    }

    func call(_ call: Call, isSendingVideo: Bool) {}
}

extension CallViewController: VoIPManagerVideoDelegate {
    func updateCall(with video: Bool) {
        enableLocalVideo(video)
    }
}

extension CallViewController: CallKitManagerAudioStateDelegate {
    func callKitDidMuteCall(_ isMuted: Bool) {
        DispatchQueue.main.async {
            self.callView.setMuteButtonSelected(isMuted)
        }
    }

    func callKitDidHoldCall(_ isOnHold: Bool) {
        DispatchQueue.main.async {
            self.callView.setHoldButtonSelected(isOnHold)
        }
    }
}

extension CallViewController: CallDurationDelegate {
    func durationChanged(_ duration: TimeInterval, for call: Call) {
    }

    func durationStringChanged(_ durationString: String, for call: Call) {
        DispatchQueue.main.async {
            self.callView.setDuration(durationString)
        }
    }
}
