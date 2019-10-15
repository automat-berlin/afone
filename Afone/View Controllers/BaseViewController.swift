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

protocol BaseViewControllerProtocol {
    var dependencyProvider: DependencyProvider { get }
}

class BaseViewController: UIViewController, BaseViewControllerProtocol {
    var dependencyProvider: DependencyProvider {
        return (UIApplication.shared.delegate as! AppDelegate).dependencyProvider
    }

    var allowUserInterfaceStyleChanges: Bool {
        return true
    }

    var darkModeBackgroundColor: UIColor? {
        return Constants.Color.automatDarkBlue
    }
    var lightModeBackgroundColor: UIColor? {
        return Constants.Color.automatBlue
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUserInterfaceStyle()
    }

    private func setupUserInterfaceStyle() {
        guard let darkModeBackgroundColor = darkModeBackgroundColor,
            let lightModeBackgroundColor = lightModeBackgroundColor,
            allowUserInterfaceStyleChanges == true else {
                return
        }

        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                view.backgroundColor = darkModeBackgroundColor
            } else {
                view.backgroundColor = lightModeBackgroundColor
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupUserInterfaceStyle()
    }
}
