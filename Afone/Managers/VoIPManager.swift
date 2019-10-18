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
import UIKit

protocol VoIPManagerDelegate: class {

    /**
     Called after an invite was accepted. The delegate should determine if the call should be answered.

     - Parameters:
        - sessionId: The session identifier of the call.
        - videoCall: `true` if a video call should be started, otherwise `false`.
        - completion: The block to execute after the call was answered.
     */
    func answerCall(_ sessionId: Int, videoCall: Bool, completion: (NSError?) -> Void)

    /**
     Called after a call was hung up.

     - Parameters:
        - sessionId: The session identifier of the call.
        - completion: The block to execute after the call was hung up.
     */
    func hangUp(_ sessionId: Int, completion: (NSError?) -> Void)

    /**
     Called when a call should be put on hold.

     - Parameters:
        - sessionId: The session identifier of the call.
        - completion: The block to execute after the call was held.
     */
    func hold(_ sessionId: Int, completion: (NSError?) -> Void)

    /**
     Called when a call should be unheld.

     - Parameters:
        - sessionId: The session identifier of the call.
        - completion: The block to execute after the call was unheld.
     */
    func unhold(_ sessionId: Int, completion: (NSError?) -> Void)

    /**
     Called when a call’s mute state should be changed.

     - Parameters:
        - sessionId: The session identifier of the call.
        - mute: `true` if the call should be muted, `false` otherwise.
        - completion: The block to execute after the call’s mute state was changed.
     */
    func mute(_ sessionId: Int, mute: Bool, completion: (NSError?) -> Void)

    /**
     Called when a call should be rejected.

     - Parameters:
        - sessionId: The session identifier of the call.
        - code: The call rejection response code.
        - completion: The block to execute after a call was rejected.
     */
    func rejectCall(_ sessionId: Int, code: Int, completion: (NSError?) -> Void)

    /**
     Called when a DTMF signal should be sent over the current session.

     - Parameters:
        - sessionId: The session identifier of the call.
        - character: The character to send as a DTMF signal.
     */
    func sendDTMF(_ sessionId: Int, character: Character)

    /**
     Called when a call should be created.

     - Parameters:
        - to: The callee’s number.
        - hasVideo: `true` if the call also sends video, `false` otherwise.
        - completion: The block to execute after a call was created.
     */
    func createCall(to: String, hasVideo: Bool, completion: (Call?, NSError?) -> Void)

    /**
     Called on adapter initialization.

     - Parameters:
        - credentials: The server credentials used for adapter initialization.
        - completion: The block to execute after the adapter was initialized.
     */
    func initAdapter(credentials: Credentials, completion: @escaping (NSError?) -> Void)

    /// Called after the application entered into the background.
    func didEnterBackground()

    /// Called after the application entered into the foreground.
    func willEnterForeground()

    /**
     Called on session logout.

     - Parameter completion: The block to execute after a logout.
     */
    func logout(completion: (() -> Void)?)

    /**
    Cancels the login process
     */
    func cancelLogin()

    /**
     Called when settings changed and should be reloaded.

     - Parameter settings: The settings which should be reloaded.
     */
    func reload(with settings: Settings)

    /**
     Called after `CallKit` activated its session.
     */
    func startAudio()

    /**
     Called after `CallKit` deactivated its session.
     */
    func stopAudio()

    var supportsVideo: Bool { get }
    var needsCodecs: Bool { get }

    /**
     Called when local video should be enabled.

     - Parameters:
        - enable: `true` if local video should be enabled, otherwise `false`.
        - completion: The block to execute after local video was enabled.
     */
    func enableLocalVideo(_ enable: Bool, completion: ((Bool) -> Void)?)

    /**
     Called when remote video should be enabled.

     - Parameters:
        - enable: `true` if remote video should be enabled, otherwise `false`.
        - completion: The block to execute after remote video was enabled.
     */
    func enableRemoteVideo(_ enable: Bool, completion: ((Bool) -> Void)?)

    /**
     Toggles the camera position (front / back).

     - Parameter completion: The block to execute after the camera was toggled.
     */
    func toggleCameraPosition(completion: (NSError?) -> Void)

    /// An array of audio codecs supported by the backend.
    var audioCodecs: [Codec] { get }

    /// An array of video codecs supported by the backend.
    var videoCodecs: [Codec] { get }

     /// An array of SRTP options supported by the backend.
    var srtpOptions: [SRTP] { get }

    /// The view on which a local video during a video call is rendered.
    var localVideoView: UIView? { get }

     /// The view on which a remote video during a video call is rendered.
    var remoteVideoView: UIView? { get }
}

extension VoIPManagerDelegate {
    var supportsVideo: Bool {
        return true
    }

    var needsCodecs: Bool {
        return true
    }
}

protocol VoIPManagerVideoDelegate: class {
    func updateCall(with video: Bool)
}

class VoIPManager: NSObject {

    weak var delegate: VoIPManagerDelegate?
    weak var videoDelegate: VoIPManagerVideoDelegate?
    weak var dependencyProvider: DependencyProvider?

    private(set) var observers = NSHashTable<VoIPCallingProtocol>.weakObjects()
}

extension VoIPManager {

    func answerCall(_ sessionId: Int, videoCall: Bool, completion: (NSError?) -> Void) {
        delegate?.answerCall(sessionId, videoCall: videoCall, completion: completion)
    }

    func hangUp(_ sessionId: Int, completion: (NSError?) -> Void) {
        delegate?.hangUp(sessionId, completion: completion)
    }

    func rejectCall(_ sessionId: Int, code: Int, completion: (NSError?) -> Void) {
        delegate?.rejectCall(sessionId, code: code, completion: completion)
    }

    func mute(_ sessionId: Int, mute: Bool, completion: (NSError?) -> Void) {
        delegate?.mute(sessionId, mute: mute, completion: completion)
    }

    func hold(_ sessionId: Int, completion: (NSError?) -> Void) {
        delegate?.hold(sessionId, completion: completion)
    }

    func unhold(_ sessionId: Int, completion: (NSError?) -> Void) {
        delegate?.unhold(sessionId, completion: completion)
    }

    func sendDTMF(_ sessionId: Int, character: Character) {
        delegate?.sendDTMF(sessionId, character: character)
    }

    func createCall(to: String, hasVideo: Bool, completion: (Call?, NSError?) -> Void) {
        delegate?.createCall(to: to, hasVideo: hasVideo, completion: completion)
    }

    func initAdapter(credentials: Credentials, completion: @escaping (NSError?) -> Void) {
        delegate?.initAdapter(credentials: credentials, completion: completion)
        if let settings = dependencyProvider?.settings {
            reload(with: settings)
        }
    }

    func didEnterBackground() {
        delegate?.didEnterBackground()
    }

    func willEnterForeground() {
        delegate?.willEnterForeground()
    }

    func logout(completion: (() -> Void)?) {
        delegate?.logout(completion: completion)
    }

    func cancelLogin() {
        delegate?.cancelLogin()
    }

    var audioCodecs: [Codec]? {
        return delegate?.audioCodecs
    }
    var videoCodecs: [Codec]? {
        return delegate?.videoCodecs
    }

    var srtpOptions: [SRTP]? {
        return delegate?.srtpOptions
    }

    func reload(with settings: Settings) {
        delegate?.reload(with: settings)
    }

    func gotIncomingCall(_ call: Call) {
        observers.allObjects.forEach { observer in
            observer.gotIncomingCall(call)
        }
    }

    func didAnswerCall(_ call: Call) {
        observers.allObjects.forEach { observer in
            observer.didAnswerCall(call)
        }
    }

    func gotMissedCall(_ call: Call) {
        observers.allObjects.forEach { observer in
            observer.gotMissedCall(call)
        }
    }

    func startAudio() {
        delegate?.startAudio()
    }

    func stopAudio() {
        delegate?.stopAudio()
    }

    func enableLocalVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
        delegate?.enableLocalVideo(enable, completion: completion)
    }

    func enableRemoteVideo(_ enable: Bool, completion: ((Bool) -> Void)?) {
        delegate?.enableRemoteVideo(enable, completion: completion)
    }

    func toggleCameraPosition(completion: (NSError?) -> Void) {
        delegate?.toggleCameraPosition(completion: completion)
    }

    func updateCall(with video: Bool) {
        videoDelegate?.updateCall(with: video)
    }

    var remoteVideoView: UIView? {
        return delegate?.remoteVideoView
    }

    var localVideoView: UIView? {
        return delegate?.localVideoView
    }

    var supportsVideo: Bool? {
        return delegate?.supportsVideo
    }

    var needsCodecs: Bool? {
        return delegate?.needsCodecs
    }
}

extension VoIPManager: CallKitManagerDelegate {
    func callKitShouldStartAudio() {
        startAudio()
    }

    func callKitShouldStopAudio() {
        stopAudio()
    }

    func performStartCall(to: String, hasVideo: Bool, completion: (Call?, NSError?) -> Void) {
        createCall(to: to, hasVideo: hasVideo) { (call, error) in
            if let call = call {
                dependencyProvider?.tabBarController?.showCallScreen(sender: nil, call: call)
            }
            completion(call, error)
        }
    }
}

// MARK: Observers

extension VoIPManager {
    func addObserver(_ observer: VoIPCallingProtocol) {
        observers.add(observer)
    }

    func removeObserver(_ observer: VoIPCallingProtocol) {
        observers.remove(observer)
    }

    func removeAllObservers() {
        observers.removeAllObjects()
    }
}
