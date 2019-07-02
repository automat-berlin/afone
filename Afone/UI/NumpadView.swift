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

@objc protocol NumpadViewDelegate: NSObjectProtocol {
    func dialerNumpadDidTap(key: DialerCircleButton)
    @objc optional func dialerNumpadDidLongTap0(key: DialerCircleButton)
}

class NumpadView: LoadableFromXibView {

    private var dialerKeys: [DialerCircleButton]?

    weak var delegate: NumpadViewDelegate?

    @IBOutlet weak var numpadStackView: UIStackView!
    @IBOutlet private var rowStackViews: [UIStackView]!

    @IBOutlet private weak var keyOne: DialerCircleButton!
    @IBOutlet private weak var keyTwo: DialerCircleButton!
    @IBOutlet private weak var keyThree: DialerCircleButton!
    @IBOutlet private weak var keyFour: DialerCircleButton!
    @IBOutlet private weak var keyFive: DialerCircleButton!
    @IBOutlet private weak var keySix: DialerCircleButton!
    @IBOutlet private weak var keySeven: DialerCircleButton!
    @IBOutlet private weak var keyEight: DialerCircleButton!
    @IBOutlet private weak var keyNine: DialerCircleButton!
    @IBOutlet private weak var keyAsterisk: DialerCircleButton!
    @IBOutlet private weak var keyZero: DialerCircleButton!
    @IBOutlet private weak var keyHash: DialerCircleButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureKeys()
    }

    private func configureKeys() {
        let dialerKeys: [DialerCircleButton] = [ keyOne, keyTwo, keyThree,
                                                 keyFour, keyFive, keySix,
                                                 keySeven, keyEight, keyNine,
                                                 keyAsterisk, keyZero, keyHash ]

        for index in 0..<dialerKeys.count {
            let key = dialerKeys[index]
            key.dialButton.tag = index
            key.dialButton.addTarget(self, action: #selector(dialerTapKeyAction), for: .touchDown)
        }

        keyAsterisk.imageView.image = UIImage(named: "asterisk")
        keyAsterisk.imageView.isHidden = false
        keyAsterisk.mainLabel.isHidden = true

        keyHash.imageView.image = UIImage(named: "uppercasedHashtag")
        keyHash.imageView.isHidden = false
        keyHash.mainLabel.isHidden = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(dialerLongTap0Action))
        longPress.minimumPressDuration = 1
        keyZero.addGestureRecognizer(longPress)

        self.dialerKeys = dialerKeys
    }

    @objc private func dialerTapKeyAction(sender: UIControl) {
        delegate?.dialerNumpadDidTap(key: dialerKey(tag: sender.tag)!)
    }

    @objc private func dialerLongTap0Action() {
        delegate?.dialerNumpadDidLongTap0?(key: keyZero)
    }

    private func dialerKey(tag: Int) -> DialerCircleButton? {
        return dialerKeys?[tag]
    }
}
