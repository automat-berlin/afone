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

class DialerViewController: BaseViewController, DialerViewDelegate {

    @IBOutlet private weak var dialerView: DialerView!

    private let initialPrefix = ""
    private var deletionCount = UInt(0)
    private let recentlyDialedNumberKey = "recentlyDialedNumber"

    override func viewDidLoad() {
        super.viewDidLoad()

        dialerView.delegate = self
        dialerView.layer.cornerRadius = 8
        dialerView.layer.masksToBounds = true
        dialerView.numberTextView.text = initialPrefix
    }

    private func canDeleteCharacter(fromNumber number: String?) -> Bool {
        guard var number = number else { return false }

        if number.count < 2 {
            return true
        }

        let index = number.index(number.startIndex, offsetBy: 2)
        let firstTwoChars = number[..<index]

        if firstTwoChars == "00" {
            number = String(number[index...])
            number = "+" + number
        }

        if number == initialPrefix {
            return false
        }

        return true
    }

    private func deleteNumber() {
        if dialerView.numberTextView.isFirstResponder {
            dialerView.numberTextView.deleteBackward()
        } else {
            guard var string = dialerView.numberTextView.text else { return }
            if !string.isEmpty {
                string = (string as NSString).substring(to: string.count - 1)
            }
            dialerView.numberTextView.text = string
        }
    }

    @objc private func startDeletingCharacters() {
        var delay = 0.25

        if canDeleteCharacter(fromNumber: dialerView.numberTextView.text) {
            if deletionCount >= 10 {
                delay = 0.05
            } else if deletionCount >= 3 {
                delay = 0.15
            }

            deleteNumber()
            deletionCount += 1

            perform(#selector(startDeletingCharacters), with: nil, afterDelay: delay)
        }
    }

    // MARK: DialerViewDelegate

    func dialerNumpadDidTap(key: DialerCircleButton) {
        if dialerView.numberTextView.isFirstResponder {
            dialerView.numberTextView.insertText(key.mainText)
        } else {
            dialerView.numberTextView.text = (dialerView.numberTextView.text ?? "") + key.mainText
        }
    }

    func dialerNumpadDidLongTap0(key: DialerCircleButton) {

        guard let number = dialerView.numberTextView.text else { return }

        var range = NSRange(location: number.count - 1, length: 1)

        if dialerView.numberTextView.isFirstResponder, let selectedRange = dialerView.numberTextView.selectedTextRange {
            let location = dialerView.numberTextView.offset(from: dialerView.numberTextView.beginningOfDocument, to: selectedRange.start)
            range = NSRange(location: location - 1, length: 1)
        }

        let num = number as NSString
        dialerView.numberTextView.text = num.replacingCharacters(in: range, with: "+")
    }

    func dialerNumpadDidEditText() {
    }

    func didPressDeleteButton() {
        deleteNumber()
    }

    func didLongPressDeleteButton() {
        startDeletingCharacters()
    }

    func didStopLongPressDeleteButton() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startDeletingCharacters), object: nil)
        deletionCount = 0
    }

    func dialerDidTapCall() {
        if dialerView.numberTextView.text.isEmpty {
            dialerView.numberTextView.text = recentlyDialedNumber()
            return
        }

        dialerView.isCallEnabled = false

        Permissions.requestCallPermissions([.audio, .video]) { [weak self] (accessGranted) in
            guard let to = self?.dialerView.numberTextView.text,
                accessGranted else {
                    DispatchQueue.main.async {
                        self?.dialerView.isCallEnabled = true
                        if !accessGranted {
                            AlertHelper.showPermissionsAlert(on: self)
                        }
                    }
                    return
            }

            guard self?.areAudioCodecsEmpty == false else {
                DispatchQueue.main.async {
                    self?.dialerView.isCallEnabled = true
                    AlertHelper.showNoCodecsAlert(on: self)
                }
                return
            }

            let normalizedTo = PhoneNumberNormalizer.cleanupString(to, fromCharacters: "/ ()-")
            self?.saveNumberToUserDefaults(number: normalizedTo)

            self?.dependencyProvider.calling.createCall(to: normalizedTo, hasVideo: false) { [weak self] in
                DispatchQueue.main.async {
                    self?.dialerView.isCallEnabled = true
                }
            }
        }
    }
}

// MARK: Codecs

extension DialerViewController {
    var areAudioCodecsEmpty: Bool {
        return dependencyProvider.settings.codecs.filter { $0.type == .audio }.isEmpty
    }
}

// MARK: UserDefaults

extension DialerViewController {
    private func saveNumberToUserDefaults(number: String) {
        UserDefaults.standard.setValue(number, forKey: recentlyDialedNumberKey)
    }

    private func recentlyDialedNumber() -> String? {
        return UserDefaults.standard.string(forKey: recentlyDialedNumberKey)
    }
}
