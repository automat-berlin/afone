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
import QuartzCore

class CircleAnimation: NSObject, CAAnimationDelegate {

    private let kTouchAnimationDuration: CFTimeInterval = 0.15
    private let kTapCircleStartDiameter: CGFloat = 0.0

    let layer: CAShapeLayer

    static func createCircleAnimationUsingSuperlayer(_ superlayer: CALayer) -> CircleAnimation {
        let layer = CAShapeLayer()

        superlayer.insertSublayer(layer, at: 0)

        return CircleAnimation(layer: layer)
    }

    init(layer: CAShapeLayer) {
        self.layer = layer

        super.init()

        configureLayer()
    }

    private func configureLayer() {
        let startCirclePath = circlePath(diameter: kTapCircleStartDiameter)

        layer.fillColor = UIColor(white: 1.0, alpha: 0.35).cgColor
        layer.path = startCirclePath?.cgPath
    }

    private func circlePath(diameter: CGFloat) -> UIBezierPath? {
        let radius: CGFloat = diameter / 2.0

        guard let superlayer = layer.superlayer else {
            return nil
        }

        let centerPoint = CGPoint(x: superlayer.bounds.size.width / 2.0, y: superlayer.bounds.size.height / 2.0)

        return UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
    }

    // MARK: Animation

    func growAnimation() {
        guard let superlayer = layer.superlayer else {
            return
        }

        let startingCirclePath = circlePath(diameter: kTapCircleStartDiameter)
        let endingCirclePath = circlePath(diameter: superlayer.bounds.size.width)

        let tapCircleGrowthAnimation = CABasicAnimation(keyPath: "path")
        tapCircleGrowthAnimation.duration = kTouchAnimationDuration
        tapCircleGrowthAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        tapCircleGrowthAnimation.fromValue = startingCirclePath?.cgPath
        tapCircleGrowthAnimation.toValue = endingCirclePath?.cgPath
        tapCircleGrowthAnimation.fillMode = .forwards
        tapCircleGrowthAnimation.isRemovedOnCompletion = false

        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.duration = kTouchAnimationDuration
        fadeIn.timingFunction = CAMediaTimingFunction(name: .linear)
        fadeIn.fromValue = 0.0
        fadeIn.toValue = 1.0
        fadeIn.fillMode = .forwards
        fadeIn.isRemovedOnCompletion = false

        layer.add(tapCircleGrowthAnimation, forKey: "animationPath")
        layer.add(fadeIn, forKey: "opacityAnimation")
    }

    func shrinkAnimation() {

        var startingOpacity: Float = 1.0

        if let animationKeys = layer.animationKeys(),
            let presentationLayer = layer.presentation() {
            startingOpacity = animationKeys.count > 0 ? layer.opacity : presentationLayer.opacity
        }

        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.setValue("fadeOut", forKey: "id")
        fadeOut.fromValue = startingOpacity
        fadeOut.toValue = 0.0
        fadeOut.duration = kTouchAnimationDuration
        fadeOut.fillMode = .forwards
        fadeOut.isRemovedOnCompletion = false
        fadeOut.delegate = self

        layer.add(fadeOut, forKey: "opacityAnimation")
    }

    func forceLayerRemoval() {
        layer.removeFromSuperlayer()
    }

    // MARK: CAAnimationDelegate

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        forceLayerRemoval()
    }
}
