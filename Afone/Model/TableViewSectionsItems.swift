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

enum Item {
    case textField(text: String?, placeholder: String?, action: (((String) -> Void)))
    case checkmark(text: String?, accessoryType: UITableViewCell.AccessoryType, transport: Transport?, srtp: SRTP.SrtpPolicyType?, action: (() -> Void))
    case imageCheckmark(text: String?, accessoryType: UITableViewCell.AccessoryType, image: UIImage?, action: (() -> Void))
    case link(text: String, detailText: String? = nil, accessoryType: UITableViewCell.AccessoryType = .none, action: (() -> Void))
    case toggle(dataSource: ToggleItemDataSource?)
}

struct Section {
    let title: String
    let items: [Item]
}

protocol ToggleItemDataSource: class {
    var title: String { get }
    var value: Bool { get set }
    var isEnabled: Bool { get }
}
