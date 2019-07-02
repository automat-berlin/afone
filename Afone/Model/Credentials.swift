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
import CodableKeychain
import CocoaLumberjack

enum Transport: Int, Codable {
    case udp
    case tcp
    case tls
}

struct Credentials: KeychainStorable {
    struct Advanced: KeychainStorable {
        // General
        var port: Int = Int(Constants.SIP.sipServerPort)
        var localPort: Int = Int(Constants.SIP.localSIPPort)
        var outboundServer: String?
        var outboundPort: Int = 0
        var authName: String?
        var displayName: String?

        // Transport
        var transport: Transport = .udp

        // STUN
        var stunServer: String?
        var stunPort: Int = 0

        // TLS
        var verifyTLS: Bool = false

        private enum CodingKeys: String, CodingKey {
            case port
            case localPort
            case outboundServer
            case outboundPort
            case authName
            case displayName
            case transport
            case stunServer
            case stunPort
            case verifyTLS
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            port = try values.decode(Int.self, forKey: .port)
            localPort = try values.decode(Int.self, forKey: .localPort)
            outboundServer = try values.decodeIfPresent(String.self, forKey: .outboundServer)
            outboundPort = try values.decode(Int.self, forKey: .outboundPort)
            authName = try values.decodeIfPresent(String.self, forKey: .authName)
            displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
            transport = try values.decode(Transport.self, forKey: .transport)
            stunServer = try values.decodeIfPresent(String.self, forKey: .stunServer)
            stunPort = try values.decode(Int.self, forKey: .stunPort)
            verifyTLS = try values.decode(Bool.self, forKey: .verifyTLS)
        }

        init(port: Int, localPort: Int, outboundServer: String?, outboundPort: Int = 0, authName: String?, displayName: String?,
             transport: Transport = .udp, stunServer: String?, stunPort: Int = 0, verifyTLS: Bool = false) {
            self.port = port
            self.localPort = localPort
            self.outboundServer = outboundServer
            self.outboundPort = outboundPort
            self.authName = authName
            self.displayName = displayName
            self.transport = transport
            self.stunServer = stunServer
            self.stunPort = stunPort
            self.verifyTLS = verifyTLS
        }
    }

    var login: String?
    var password: String?
    var sipServer: String?
    var advanced: Advanced = Advanced(port: Int(Constants.SIP.sipServerPort), localPort: Int(Constants.SIP.localSIPPort),
                                      outboundServer: nil, authName: nil, displayName: nil, stunServer: nil)
}
extension Credentials {
    var account: String { return Constants.Keychain.serviceKey }
    var accessible: Keychain.AccessibleOption { return .whenPasscodeSetThisDeviceOnly }
}

extension Credentials.Advanced {
    var account: String { return "advanced" }
    var accessible: Keychain.AccessibleOption { return .whenPasscodeSetThisDeviceOnly }
}
