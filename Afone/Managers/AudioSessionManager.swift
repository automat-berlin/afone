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
import AVFoundation

class AudioSessionManager {

    enum AudioSessionType: Int {
        case restore
        case voice
        case video

        func configure() {
            let audioSession = AVAudioSession.sharedInstance()
            var category: AVAudioSession.Category
            var mode: AVAudioSession.Mode

            switch self {
            case .restore:
                category = .ambient
                mode = .default
            case .voice:
                category = .playAndRecord
                mode = .voiceChat
            case .video:
                category = .playAndRecord
                mode = .videoChat
            }

            do {
                try audioSession.setCategory(category, mode: mode, options: .allowBluetooth)
            } catch {
                DDLogError("🔊 Error while setting audio session category: \(String(describing: error.localizedDescription)).")
            }

            guard self != .restore else {
                DDLogInfo("🔊 Successfully configured audio mode \(self)")
                return
            }

            do {
                try audioSession.setPreferredIOBufferDuration(Constants.Call.audioPrefferedBufferDurration)
            } catch {
                DDLogError("🔊 Error while setting preferred IOBufferDuration: \(String(describing: error.localizedDescription)).")
            }

            do {
                try audioSession.setPreferredSampleRate(Double(Constants.Call.maxAudioBitrate))
            } catch {
                DDLogError("🔊 Error while setting preferred sample rate: \(String(describing: error.localizedDescription)).")
            }

            do {
                try audioSession.setActive(true, options: [])
            } catch {
                DDLogError("🔊 Error while setting audio sesssion active: \(String(describing: error.localizedDescription)).")
            }

            DDLogInfo("🔊 Successfully configured audio mode \(self)")
        }
    }

    static func configureAudioSession(type: AudioSessionType) {
        type.configure()
    }

    static func routeAudioToSpeaker(completion: (Bool) -> Void) {
        AudioSessionManager.configureAudioSession(type: .video)
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            completion(false)
            return
        }

        completion(true)
    }

    static func routeAudioToReceiver(completion: (Bool) -> Void) {
        AudioSessionManager.configureAudioSession(type: .voice)
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        } catch {
            completion(false)
            return
        }

        completion(true)
    }

}
