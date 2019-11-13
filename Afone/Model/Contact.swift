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

import Foundation
import Contacts

class Contact {

    var givenName: String
    var familyName: String
    var organizationName: String
    var phoneNumbers: [String]

    init(givenName: String, familyName: String, organizationName: String, phoneNumbers: [String]) {
        self.givenName = givenName
        self.familyName = familyName
        self.organizationName = organizationName
        self.phoneNumbers = phoneNumbers
    }
}

extension Contact {

    /// Can be used in UI elements as a title.
    var mainDescription: String {
        displayName.isEmpty ? alternateDisplayName : displayName
    }

    /// Can be used in UI elements as a subtitle.
    var secondaryDescription: String {
        displayName.isEmpty ? "" : organizationName
    }

    @objc var sortOrder: String {
        let order = CNContactsUserDefaults.shared().sortOrder
        var givenOrFamilyName: String
        switch order {
        case .familyName:
            givenOrFamilyName = familyName.isEmpty ? givenName : familyName
        case .givenName:
            givenOrFamilyName = givenName.isEmpty ? familyName : givenName
        default:
            givenOrFamilyName = familyName.isEmpty ? givenName : familyName
        }
        let businessOrPhone = organizationName.isEmpty ? phoneNumbers.first ?? "" : organizationName
        return givenOrFamilyName.isEmpty ? businessOrPhone : givenOrFamilyName
    }
}

extension Contact {

    private var displayName: String {
        givenName.isEmpty ? familyName : givenName + " " + familyName
    }

    private var alternateDisplayName: String {
        !organizationName.isEmpty ? organizationName : (phoneNumbers.first ?? "")
    }
}
