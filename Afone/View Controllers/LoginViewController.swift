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

class LoginViewController: BaseViewController {

    @IBOutlet private weak var loginField: UITextField!
    @IBOutlet private weak var passwordField: UITextField!
    @IBOutlet private weak var sipServerField: UITextField!
    @IBOutlet private weak var errorLabel: UILabel!

    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var advancedButton: UIButton!

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var embeddingView: UIView!

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var formViewLayout: FormViewLayout?

    override var allowUserInterfaceStyleChanges: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        formViewLayout = FormViewLayout(view: view, contentView: embeddingView)
        formViewLayout?.setupConstraints()

        activityIndicator.isHidden = true

        loginButton.configureWithBackgroundColor(Constants.Color.automatDarkBlue, highlightedColor: Constants.Color.automatLightBlue, disabledColor: .gray, cornerRadius: 8.0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let credentials = dependencyProvider.keychainManager.credentials {
            dependencyProvider.credentials = credentials
            prefillTextFields(with: credentials)
            login()
        }
    }

    // empty, but needed for a proper dismiss animation that is configured in storyboard
    @IBAction func dismissAction(segue: UIStoryboardSegue) {
    }

    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {
        let segue = UIStoryboardSegue(identifier: unwindSegue.identifier, source: unwindSegue.source, destination: unwindSegue.destination)
        segue.perform()
    }

    @IBAction func dismissAllResponders() {
        loginField.resignFirstResponder()
        passwordField.resignFirstResponder()
        sipServerField.resignFirstResponder()
    }

    @IBAction func login() {
        dismissAllResponders()

        guard let login = loginField.text,
            let password = passwordField.text,
            let sipServer = sipServerField.text else {
                return
        }

        setUIElementsEnabled(false)
        changeLoginButtonToCancel()

        errorLabel.text = nil
        errorLabel.isHidden = true
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false

        dependencyProvider.credentials.login = login
        dependencyProvider.credentials.password = password
        dependencyProvider.credentials.sipServer = sipServer
        dependencyProvider.voipManager.initAdapter(credentials: dependencyProvider.credentials) { [weak self] (error) in
            self?.activityIndicator.stopAnimating()
            self?.setUIElementsEnabled(true)
            self?.changeCancelButtonToLogin()

            if error == nil {
                self?.performSegue(withIdentifier: "showMainApp", sender: self)
                self?.dependencyProvider.keychainManager.credentials = self?.dependencyProvider.credentials
            } else {
                self?.errorLabel.text = error?.userInfo["description"] as? String
                self?.errorLabel.isHidden = false
            }
        }
    }
}

extension LoginViewController {

    private func prefillTextFields(with credentials: Credentials) {
        loginField.text = credentials.login
        passwordField.text = credentials.password
        sipServerField.text = credentials.sipServer
    }

    private func setUIElementsEnabled(_ isEnabled: Bool) {
        for control in [loginField, passwordField, sipServerField, advancedButton] {
            control?.isEnabled = isEnabled
        }
    }

    private func changeLoginButtonToCancel() {
        loginButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        loginButton.removeTarget(self, action: nil, for: .allEvents)
        loginButton.addTarget(self, action: #selector(cancelLogin), for: .touchUpInside)
    }

    private func changeCancelButtonToLogin() {
        loginButton.setTitle(NSLocalizedString("Login", comment: ""), for: .normal)
        loginButton.removeTarget(self, action: nil, for: .allEvents)
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
    }

    @objc private func cancelLogin() {
        dependencyProvider.voipManager.cancelLogin()
        changeCancelButtonToLogin()
        activityIndicator.stopAnimating()
        setUIElementsEnabled(true)
    }
}
