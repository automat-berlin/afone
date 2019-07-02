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

class DialerKeyControl: LoadableFromXibView, ABButtonDelegate {

    @IBOutlet weak var dialButton: ABButton!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBInspectable var mainText: String = ""
    @IBInspectable var subtitleText: String = ""

    @IBInspectable var useRegularFontForMainLabel: Bool = false

    @IBInspectable var mainLabelSizeRelative: CGFloat = 0.0
    @IBInspectable var subtitleLabelSizeRelative: CGFloat = 0.0

    @IBInspectable var mainLabelYTranslationRelative: CGFloat = 0.0
    @IBInspectable var subtitleLabelYTranslationRelative: CGFloat = 0.0

    private var touchStartDate: Date = Date()
    private var circleAnimation: CircleAnimation?
    private var dtmfManager = DTMFManager()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupIBDefaults()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupIBDefaults()
    }

    private func setupIBDefaults() {
        translatesAutoresizingMaskIntoConstraints = false

        useRegularFontForMainLabel = false

        mainLabelSizeRelative = 1.0
        subtitleLabelSizeRelative = 1.0

        mainLabelYTranslationRelative = 0
        subtitleLabelYTranslationRelative = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        assignIBValues()

        dialButton.delegate = self
    }

    override func prepareForInterfaceBuilder() {
        assignIBValues()
        super.prepareForInterfaceBuilder()
    }

    override func layoutIfNeeded() {
        assignIBValues()
        super.layoutIfNeeded()
    }

    private func assignIBValues() {
        if useRegularFontForMainLabel {
            mainLabel.font = UIFont.systemFont(ofSize: mainLabel.font.pointSize, weight: .regular)
        }

        mainLabel.text = mainText
        subtitleLabel.text = subtitleText

        let mainLabelTransform = CGAffineTransform(scaleX: mainLabelSizeRelative, y: mainLabelSizeRelative)
        let subtitleLabelTransform = CGAffineTransform(scaleX: subtitleLabelSizeRelative, y: subtitleLabelSizeRelative)

        mainLabelTransform.translatedBy(x: 0.0, y: mainLabelYTranslationRelative * frame.size.height)
        subtitleLabelTransform.translatedBy(x: 0.0, y: subtitleLabelYTranslationRelative * frame.size.height)

        mainLabel.transform = mainLabelTransform
        subtitleLabel.transform = subtitleLabelTransform
    }

    // MARK: Animation

    private func startAnimation() {
        circleAnimation = CircleAnimation.createCircleAnimationUsingSuperlayer(layer)
        circleAnimation?.growAnimation()
    }

    private func stopAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.circleAnimation?.shrinkAnimation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.circleAnimation?.forceLayerRemoval()

                self.forceSublayerCleanup(without: self.circleAnimation)
            })
        }
    }

    private func forceSublayerCleanup(without animation: CircleAnimation?) {
        // Due to iOS 10 bugs related to not removing sublayer a second forced removed is called after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.removeCAShapeSublayers(without: self.circleAnimation)
        }
    }

    private func removeCAShapeSublayers(without animation: CircleAnimation?) {
        guard let sublayers = layer.sublayers else {
            return
        }

        for layer in sublayers {
            if layer is CAShapeLayer && circleAnimation?.layer != layer {
                layer.removeFromSuperlayer()
            }
        }
    }

    // MARK: ABButtonDelegate

    func touchesBegan(for button: UIButton, touches: Set<UITouch>, with event: UIEvent?) {
        startAnimation()

        FeedbackManager.giveFeedback()
        playSound()
    }

    func touchesEnded(for button: UIButton, touches: Set<UITouch>, with event: UIEvent?) {
        stopSound()
        stopAnimation()
    }

    func touchesCancelled(for button: UIButton, touches: Set<UITouch>, with event: UIEvent?) {
        stopSound()
        stopAnimation()
    }

    // MARK: DTMF sounds

    private func playSound() {
        touchStartDate = Date()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(stopButtonAnimationAndSound), object: nil)

        // play sound
        dtmfManager.playTone(for: mainText)

        perform(#selector(stopButtonAnimationAndSound), with: nil, afterDelay: 1.0)
    }

    private func stopSound() {
        let passedTime = touchStartDate.timeIntervalSinceNow * (-1000)
        var delay: TimeInterval = 0

        // For very short touches, we need to artificially play the sound longer to avoid ugly sounds
        if passedTime <= 250 {
            delay = 0.1
        }

        perform(#selector(stopButtonAnimationAndSound), with: nil, afterDelay: delay)
    }

    @objc private func stopButtonAnimationAndSound() {
        dtmfManager.stopTone()
        stopAnimation()
    }
}
