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

class AutomatPresentSegue: UIStoryboardSegue {

    override func perform() {
        present()
    }

    private func present() {
        let fromViewController = source
        let toViewController = destination

        let container = fromViewController.view.superview
        let center = fromViewController.view.center

        toViewController.view.transform = CGAffineTransform(scaleX: 3.25, y: 3.25)
        toViewController.view.center = center
        toViewController.view.alpha = 0.0

        container?.addSubview(toViewController.view)

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            toViewController.view.transform = CGAffineTransform.identity
            toViewController.view.alpha = 1.0
        }) { _ in
            fromViewController.present(toViewController, animated: false, completion: nil)
        }
    }

}

class AutomatDismissSegue: UIStoryboardSegue {

    override func perform() {
        dismiss()
    }

    private func dismiss() {
        let fromViewController = source
        let toViewController = destination

        fromViewController.view.superview?.insertSubview(toViewController.view, at: 0)
        fromViewController.navigationController?.setNavigationBarHidden(true, animated: true)

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            fromViewController.view.transform = CGAffineTransform(scaleX: 3.25, y: 3.25)
            fromViewController.view.alpha = 0.0
        }) { _ in
            fromViewController.dismiss(animated: false, completion: nil)
        }
    }
}
