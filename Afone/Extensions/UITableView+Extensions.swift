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

extension UITableViewCell: ReusableIdentifier {}

extension UITableView {
    func register<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    func register<T: UITableViewCell>(_: T.Type) where T: ReusableNib {
        let nib = UINib(nibName: T.nibName, bundle: nil)
        register(nib, forCellReuseIdentifier: T.reuseIdentifier)
    }

    @objc func registerReusableCell(_ T: UITableViewCell.Type) {
        if let S = T.self as? ReusableNib.Type {
            let nib = UINib(nibName: S.nibName, bundle: nil)
            register(nib, forCellReuseIdentifier: S.reuseIdentifier)
        } else {
            register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
        }
    }

    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }

    @objc func dequeueReusableCell(_ T: UITableViewCell.Type, forIndexPath indexPath: IndexPath) -> UITableViewCell {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath)
    }

    func register<T: UITableViewHeaderFooterView>(_: T.Type) where T: ReusableIdentifier {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }

    func register<T: UITableViewHeaderFooterView>(_: T.Type) where T: ReusableNib {
        let nib = UINib(nibName: T.nibName, bundle: nil)
        register(nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }

    @objc func registerHeaderFooterView(_ T: UITableViewHeaderFooterView.Type) {
        if let S = T.self as? ReusableNib.Type {
            let nib = UINib(nibName: S.nibName, bundle: nil)
            register(nib, forHeaderFooterViewReuseIdentifier: S.reuseIdentifier)
        } else if let S = T.self as? ReusableIdentifier.Type {
            register(S.self, forHeaderFooterViewReuseIdentifier: S.reuseIdentifier)
        }
    }

    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T where T: ReusableIdentifier {
        return dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as! T
    }

    @objc func dequeueReusableHeaderFooterView(_ T: UITableViewHeaderFooterView.Type) -> UITableViewHeaderFooterView? {
        guard let S = T.self as? ReusableIdentifier.Type else { return nil }
        return dequeueReusableHeaderFooterView(withIdentifier: S.reuseIdentifier)
    }
}
