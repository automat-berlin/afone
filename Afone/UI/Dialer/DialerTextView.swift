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

class DialerTextView: UITextView {
    var maxFontSize: CGFloat = 17.0
    var minFontSize: CGFloat = 12.0

    override var text: String! {
        didSet {
            adjustFontSize()
        }
    }

    func adjustFontSize() {
        var currentFontSize = maxFontSize
        var textSize = CGSize.zero

        while currentFontSize > minFontSize && currentFontSize <= maxFontSize {
            let font = UIFont.systemFont(ofSize: CGFloat(currentFontSize), weight: UIFont.Weight.light)
            textSize = text?.size(withAttributes: [NSAttributedString.Key.font: font]) ?? CGSize.zero
            if textSize.width > frame.size.width {
                currentFontSize -= 1
            } else { // In case we have found the proper font size, next iteration is not needed
                break
            }
        }

        self.font = UIFont.systemFont(ofSize: CGFloat(currentFontSize), weight: UIFont.Weight.light)
    }
}
