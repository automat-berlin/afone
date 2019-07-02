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

protocol CallViewDelegate: class {
    func callViewDidToggleMute(button: UIButton?)
    func callViewDidToggleHold(button: UIButton?)
    func callViewDidToggleLoudspeaker(button: UIButton?)
    func callViewDidToggleVideo(button: UIButton?)
    func callViewDidToggleCameraPosition(button: UIButton?)
    func callViewDidPressDTMF(character: Character)
    func callViewDidHangupWithButton(button: UIButton?)
    func callViewShouldUpdateSendingVideoView(view: UIView?)
    func callViewShouldUpdateReceivingVideoView(view: UIView?)
    func callViewDidHideInCallNumpadView()
    func callViewDidTapEmptySpace()
}

class CallView: LoadableFromXibView {

    weak var call: Call? {
        didSet {
            contactNameLabel.text = call?.isIncomingCall ?? false ? call?.caller : call?.callee
            callStatusLabel.text = call?.callStateString
            call?.addObserver(self)
        }
    }

    var selectSpeaker: Bool = false {
        didSet {
            speakerButton.isSelected = selectSpeaker
        }
    }

    var selectMute: Bool = false {
        didSet {
            muteButton.isSelected = selectMute
        }
    }

    weak var delegate: CallViewDelegate?

    @IBOutlet private weak var contactNameLabel: UILabel!
    @IBOutlet private weak var dtmfInputLabel: UILabel!
    @IBOutlet private weak var callStatusLabel: UILabel!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var muteLabel: UILabel!
    @IBOutlet private weak var speakerLabel: UILabel!
    @IBOutlet private weak var hangupButton: UIButton!
    @IBOutlet private weak var numpadView: NumpadView!
    @IBOutlet private weak var hideButton: UIButton!
    @IBOutlet private weak var numpadButton: UIButton!
    @IBOutlet private weak var numpadLabel: UILabel!
    @IBOutlet private weak var videoButton: UIButton!
    @IBOutlet private weak var switchButton: UIButton!
    @IBOutlet private weak var holdButton: UIButton!
    @IBOutlet private weak var standardButtonsStackView: UIStackView!
    @IBOutlet private weak var durationLabel: UILabel!

    private var dtmfInput = ""

    private var isNumpadVisibile = false

    override func awakeFromNib() {
        super.awakeFromNib()

        configure()
    }

    private func configure() {
        numpadView.delegate = self

        isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(emptySpaceTapped))
        addGestureRecognizer(tapGestureRecognizer)

        muteButton.setImage(UIImage(named: "muteHighlighted"), for: .highlighted)
        muteButton.setImage(UIImage(named: "muteHighlighted"), for: [.highlighted, .selected])
        muteButton.setImage(UIImage(named: "muteSelected"), for: .selected)

        holdButton.setImage(UIImage(named: "holdHighlighted"), for: .highlighted)
        holdButton.setImage(UIImage(named: "holdHighlighted"), for: [.highlighted, .selected])
        holdButton.setImage(UIImage(named: "holdSelected"), for: .selected)

        videoButton.setImage(UIImage(named: "videoHighlighted"), for: .highlighted)
        videoButton.setImage(UIImage(named: "videoHighlighted"), for: [.highlighted, .selected])
        videoButton.setImage(UIImage(named: "videoSelected"), for: .selected)

        switchButton.setImage(UIImage(named: "cameraHighlighted"), for: .highlighted)
        switchButton.setImage(UIImage(named: "cameraHighlighted"), for: [.highlighted, .selected])

        speakerButton.setImage(UIImage(named: "speakerHighlighted"), for: .highlighted)
        speakerButton.setImage(UIImage(named: "speakerHighlighted"), for: [.highlighted, .selected])
        speakerButton.setImage(UIImage(named: "speakerSelected"), for: .selected)

        numpadButton.setImage(UIImage(named: "numpadHighlighted"), for: .highlighted)
        numpadButton.setImage(UIImage(named: "numpadHighlighted"), for: [.highlighted, .selected])

        setNumpadVisible(false, animated: false)
    }

    private func setNumpadVisible(_ visible: Bool, animated: Bool) {

        isNumpadVisibile = visible

        let block: () -> Void = { [weak self] in
            self?.standardButtonsStackView.alpha = visible ? 0.0 : 1.0
            self?.numpadView.alpha = visible ? 1.0 : 0.0
            self?.hideButton.alpha = visible ? 1.0 : 0.0
        }

        if !animated {
            block()
            return
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            block()
        }, completion: nil)
    }

    private func setDTMFInputVisible(_ visible: Bool) {
        dtmfInputLabel.isHidden = !visible
        contactNameLabel.isHidden = visible
        callStatusLabel.isHidden = visible
    }
}

extension CallView {
    @IBAction private func numpadShowAction() {
        setNumpadVisible(true, animated: true)
    }

    @IBAction private func numpadHideAction() {
        setNumpadVisible(false, animated: true)
        setDTMFInputVisible(false)
        delegate?.callViewDidHideInCallNumpadView()
    }

    @IBAction private func muteCallAction(button: UIButton?) {
        delegate?.callViewDidToggleMute(button: button)
    }

    @IBAction private func holdCallAction(button: UIButton?) {
        delegate?.callViewDidToggleHold(button: button)
    }

    @IBAction private func speakerAction(button: UIButton?) {
        delegate?.callViewDidToggleLoudspeaker(button: button)
    }

    @IBAction private func cancelCallAction(button: UIButton?) {
        delegate?.callViewDidHangupWithButton(button: button)
    }

    @IBAction private func videoToggleAction(button: UIButton?) {
        delegate?.callViewDidToggleVideo(button: button)
    }

    @IBAction private func switchToggleAction(button: UIButton?) {
        delegate?.callViewDidToggleCameraPosition(button: button)
    }

    @objc private func emptySpaceTapped() {
        delegate?.callViewDidTapEmptySpace()
    }
}

extension CallView: NumpadViewDelegate {
    func dialerNumpadDidTap(key: DialerCircleButton) {
        if isNumpadVisibile {
            setDTMFInputVisible(true)
        }
        let index = key.mainText.startIndex
        let character = key.mainText[index]
        dtmfInput.append(character)
        dtmfInputLabel.text = dtmfInput
        delegate?.callViewDidPressDTMF(character: character)
    }
}

extension CallView: CallDelegate {
    func stateChanged(_ callState: Call.CallState, for call: Call) {
        callStatusLabel.text = call.callStateString
    }

    func call(_ call: Call, isReceivingVideo: Bool) {
    }

    func call(_ call: Call, isSendingVideo: Bool) {
        videoButton.isSelected = isSendingVideo
    }
}

// MARK: Public accessors

extension CallView {
    func setMuteButtonSelected(_ isSelected: Bool) {
        muteButton.isSelected = isSelected
    }

    func setHoldButtonSelected(_ isSelected: Bool) {
        holdButton.isSelected = isSelected
    }

    func setHoldButtonEnabled(_ isEnabled: Bool) {
        holdButton.isEnabled = isEnabled
    }

    func setCallControlButtonsEnabled(_ isEnabled: Bool) {
        videoButton.isEnabled = isEnabled
        switchButton.isEnabled = isEnabled
        holdButton.isEnabled = isEnabled
        speakerButton.isEnabled = isEnabled
    }

    func setDuration(_ duration: String) {
        durationLabel.text = duration
    }
}
