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

extension UIView {
    func constraints(affecting view: UIView) -> [NSLayoutConstraint] {
        return constraints.filter { $0.firstItem as? UIView == view || $0.secondItem as? UIView == view }
    }
}

/*
 FormViewLayout provides basic layout of login and registration view controllers as follows:
 - the content has fixed left and right margins
 - the content is filling the available screen area vertically
 - if keyboard is shown, layout is adjusted accordingly
 - activity indicator is horizontally centered and vertically positioned above the keyboard
 */

@objc class FormViewLayout: NSObject {
    private static let topMarginiOS10: CGFloat = 64.0
    private static let topMarginiOS11: CGFloat = (topMarginiOS10 - (44.0 + 20.0)) //44.0 - navigation bar, 20.0 - status bar

    private let view: UIView
    private let scrollView: UIScrollView!
    private let contentView: UIView

    var contentViewMargin: CGFloat = 12.0
    private var scrollViewBottomConstraint: NSLayoutConstraint?
    private var visibleAreaHeightConstraint: NSLayoutConstraint?

    @objc init(view: UIView, contentView: UIView) {
        self.view = view
        self.contentView = contentView
        scrollView = UIScrollView()
    }

    @objc func setupConstraints() {
        let constraintsToDeactivate = view.constraints(affecting: contentView)
        NSLayoutConstraint.deactivate(constraintsToDeactivate)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)

        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        if #available(iOS 11.0, *) {
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: FormViewLayout.topMarginiOS11).isActive = true
            scrollViewBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            scrollViewBottomConstraint?.isActive = true
        } else {
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: FormViewLayout.topMarginiOS10).isActive = true
            scrollViewBottomConstraint = view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            scrollViewBottomConstraint?.isActive = true
        }

        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: contentViewMargin).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: contentViewMargin).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -2 * contentViewMargin).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -contentViewMargin).isActive = true
        contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor, constant: -contentViewMargin).isActive = true

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let height = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return
        }

        scrollViewBottomConstraint?.constant = height

        if #available(iOS 11.0, *), let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
            scrollViewBottomConstraint?.constant = height - bottomInset // addjust by bottom safe area inset
        }

        visibleAreaHeightConstraint?.constant = -height

        view.setNeedsUpdateConstraints()

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
        }

        scrollViewBottomConstraint?.constant = 0
        visibleAreaHeightConstraint?.constant = 0

        view.setNeedsUpdateConstraints()

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
}
