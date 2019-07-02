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

protocol DialerViewDelegate: NSObjectProtocol {
    func dialerNumpadDidTap(key: DialerCircleButton)
    func dialerNumpadDidLongTap0(key: DialerCircleButton)
    func dialerNumpadDidEditText()

    func dialerDidTapCall()

    func didPressDeleteButton()
    func didLongPressDeleteButton()
    func didStopLongPressDeleteButton()
}

class DialerView: LoadableFromXibView, UITextViewDelegate, NumpadViewDelegate {

    weak var delegate: DialerViewDelegate?

    @IBOutlet weak var numberTextView: DialerTextView!

    @IBOutlet weak var padTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteButtonTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var actionsStackView: UIStackView!

    @IBOutlet weak var callButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var callButtonHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var numpadView: NumpadView! {
        didSet {
            numpadView.delegate = self
        }
    }

    var isCallEnabled: Bool {
        get {
            return callButton.isEnabled
        }

        set {
            for button in [callButton] {
                button?.isEnabled = newValue
                button?.alpha = newValue ? 1 : 0.5
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureDeleteButton()
        disableKeyboard()
        configureActionButtons()
        configureNumberTextView()
    }

    @IBAction func callAction(_ sender: UIButton) {
        delegate?.dialerDidTapCall()
    }

    @IBAction func feedbackAction(_ sender: UIButton) {
        FeedbackManager.giveFeedback()
    }

    private func configureDeleteButton() {
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressDelete))
        deleteButton.addGestureRecognizer(longPressGesture)
    }

    private func configureActionButtons() {
        callButton.layer.cornerRadius = callButtonWidthConstraint.constant / 2.0
        callButton.layer.masksToBounds = true
    }

    private func configureNumberTextView() {
        numberTextView.textContainer.maximumNumberOfLines = 1
        numberTextView.textContainer.lineBreakMode = .byTruncatingHead
        numberTextView.textContainer.lineFragmentPadding = 0
        numberTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        numberTextView.allowsEditingTextAttributes = false

        numberTextView.maxFontSize = 38
        numberTextView.minFontSize = 30

        numberTextView.delegate = self
    }

    private func disableKeyboard() {
        let dummyView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        numberTextView.inputView = dummyView
    }

    @objc func dialerNumpadDidTap(key: DialerCircleButton) {
        delegate?.dialerNumpadDidTap(key: key)
    }

    @objc func dialerNumpadDidLongTap0(key: DialerCircleButton) {
        delegate?.dialerNumpadDidLongTap0(key: key)
    }

    @objc private func deleteAction(_ sender: UIButton) {
        delegate?.didPressDeleteButton()
    }

    @objc private func didLongPressDelete(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.didLongPressDeleteButton()
        } else if recognizer.state == .ended {
            delegate?.didStopLongPressDeleteButton()
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        numberTextView.adjustFontSize()
        delegate?.dialerNumpadDidEditText()
    }
}
