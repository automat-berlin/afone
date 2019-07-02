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

class SwitchTableViewCell: UITableViewCell {

    weak var dataSource: ToggleItemDataSource? {
        didSet {
            guard let dataSource = dataSource else { return }

            textLabel?.text = dataSource.title
            switchControl.isOn = dataSource.value
            switchControl.isEnabled = dataSource.isEnabled
        }
    }

    var toggleColor: UIColor? {
        get {
            return switchControl.onTintColor
        }

        set {
            switchControl.onTintColor = newValue
        }
    }

    private var switchControl = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setUp()
    }

    private func setUp() {
        switchControl.addTarget(self, action: #selector(toggle), for: .valueChanged)
        accessoryView = switchControl
    }

    @objc private func toggle() {
        guard let dataSource = dataSource else { return }

        dataSource.value = !dataSource.value
    }
}
