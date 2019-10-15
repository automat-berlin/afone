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

class AboutViewController: BaseViewController {

    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var websiteLinkLabel: UILabel!
    @IBOutlet private weak var copyrightLabel: UILabel!

    override var darkModeBackgroundColor: UIColor? {
        return .black
    }

    override var lightModeBackgroundColor: UIColor? {
        return .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let navImage = UIImage(named: "logoBlueTransparent")
        let navImageView = UIImageView(image: navImage)
        navImageView.contentMode = .scaleAspectFit
        navImageView.frame = CGRect(x: 20, y: 0, width: 40, height: 40)

        let advancedLabel = UILabel(frame: CGRect(x: 60, y: 0, width: 100, height: 40))
        advancedLabel.text = "bout"
        advancedLabel.textColor = Constants.Color.automatBlue
        advancedLabel.font = .systemFont(ofSize: 25)

        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 140, height: 40))
        customView.addSubview(navImageView)
        customView.addSubview(advancedLabel)

        navigationItem.titleView = customView

        logoImageView.layer.masksToBounds = true
        logoImageView.layer.cornerRadius = logoImageView.frame.width / 4

        versionLabel.text = Constants.version
        websiteLinkLabel.text = Constants.website
        copyrightLabel.text = Constants.copyright
    }
}
