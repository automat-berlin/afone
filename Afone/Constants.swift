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

// Global App Constants
struct Constants {

    static let appName = "Afone"
    static let bundleId = "berlin.automat.afon"
    static let unknownString = NSLocalizedString("Unknown", comment: "")
    static let userAgent = "Afone"

    static let website = "https://automat.berlin"
    static let copyright = "Copyright ©2019 Automat Berlin GmbH.\nAll rights reserved."
    static let version = "Version \(Bundle.main.appVersion)"

    struct Sound {
        static let ringbackFileName = "Ringback.wav"
        static let elevatorMusicFileName = "Elevator-music.mp3"
    }

    struct Call {
        enum ErrorCode: Int {
            case none = 0
            case sessionIdMissing = 100
        }

        static let domain = "berlin.automat.afon.call"
        static var errorCode: ErrorCode = .none
        static let maxVideoBitrate = 3500000
        static let audioPrefferedBufferDurration = 0.005
        static let maxAudioBitrate = 44100
        static let unknownUser = Constants.unknownString
        static let callRejectedCode: Int = 480
        static let callBusyCode: Int = 486

        static let audioPtime: Int32 = 20
        static let audioMaxPtime: Int32 = 60

        static let videoMinFrameRate: Int32 = 30
        static let videoMinBitRate: Int32 = 1024
        static let videoWidth: Int32 = Int32(UIScreen.main.bounds.width * UIScreen.main.scale)
        static let videoHeight: Int32 = Int32(UIScreen.main.bounds.height * UIScreen.main.scale)

        static let allSessions: Int = -1
    }

    struct SIP {

        static let localSIPPort: Int32    = 10002
        static let localIP = "0.0.0.0"
        static let sipServerPort: Int32 = 5060
        static let sipRegistrationRefreshSeconds: Int32 = 90
        static let sipRegistrationRetry: Int32 = 2
        static let sipUnknownSessionId: Int = -1
        static let stunPort: Int = 3478
    }

    struct Color {
        static let automatBlue = UIColor(red: 45/255, green: 72/255, blue: 148/255, alpha: 1.0)
        static let automatDarkBlue = UIColor(red: 24/255, green: 38/255, blue: 77/255, alpha: 1.0)
        static let automatLightBlue = UIColor(red: 65/255, green: 92/255, blue: 168/255, alpha: 1.0)
    }

    struct Keychain {
        static let serviceKey = "credentials"
    }
}
