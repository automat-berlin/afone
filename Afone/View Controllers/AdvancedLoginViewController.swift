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

class AdvancedLoginViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!

    private enum SectionType: Int {
        case general
        case transport
        case stun
        case about
    }

    private var sections: [Section] = [Section]()
    private let cellSelector = CellSelector()

    private var formViewLayout: FormViewLayout?

    override var darkModeBackgroundColor: UIColor? {
        return .black
    }

    override var lightModeBackgroundColor: UIColor? {
        return .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableView()
        setupSections()
    }

    private func setupSections() {
        sections = [
            Section(title: NSLocalizedString("General", comment: ""), items: [
                    .textField(text: NSLocalizedString("SIP Server Port", comment: ""), placeholder: String(describing: Constants.SIP.sipServerPort), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.port = text.intValue(defaultValue: Int(Constants.SIP.sipServerPort))
                    }),
                    .textField(text: NSLocalizedString("Local Port", comment: ""), placeholder: String(describing: Constants.SIP.localSIPPort), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.localPort = text.intValue(defaultValue: Int(Constants.SIP.localSIPPort))
                    }),
                    .textField(text: NSLocalizedString("Outbound Proxy Server", comment: ""),
                               placeholder: NSLocalizedString("Disabled if left empty", comment: ""), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.outboundServer = text
                    }),
                    .textField(text: NSLocalizedString("Outbound Proxy Port", comment: ""), placeholder: NSLocalizedString("default", comment: ""), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.outboundPort = text.intValue()
                    }),
                    .textField(text: NSLocalizedString("Auth Name", comment: ""), placeholder: NSLocalizedString("login is default", comment: ""), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.authName = text
                    }),
                    .textField(text: NSLocalizedString("Display Name", comment: ""), placeholder: NSLocalizedString("login is default", comment: ""), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.displayName = text
                    })
                ]),
            Section(title: NSLocalizedString("Transport", comment: ""), items: [
                .checkmark(text: NSLocalizedString("UDP", comment: ""), accessoryType: .checkmark, transport: .udp, srtp: nil, action: { [weak self] in
                        self?.dependencyProvider.credentials.advanced.transport = .udp
                    }),
                .checkmark(text: NSLocalizedString("TCP", comment: ""), accessoryType: .none, transport: .tcp, srtp: nil, action: { [weak self] in
                        self?.dependencyProvider.credentials.advanced.transport = .tcp
                    }),
                .checkmark(text: NSLocalizedString("TLS", comment: ""), accessoryType: .none, transport: .tls, srtp: nil, action: { [weak self] in
                        self?.dependencyProvider.credentials.advanced.transport = .tls
                    })
                ]),
            Section(title: NSLocalizedString("STUN", comment: ""), items: [
                    .textField(text: NSLocalizedString("Server", comment: ""), placeholder: NSLocalizedString("Disabled if left empty", comment: ""), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.stunServer = text
                    }),
                    .textField(text: NSLocalizedString("Port", comment: ""), placeholder: String(describing: Constants.SIP.stunPort), action: { [weak self] text in
                        self?.dependencyProvider.credentials.advanced.stunPort = text.intValue(defaultValue: Constants.SIP.stunPort)
                    })
                ]),
            Section(title: NSLocalizedString("TLS Certificate", comment: ""), items: [
                .toggle(dataSource: TLSDataSource(dependencyProvider: dependencyProvider))
                ]),
            Section(title: NSLocalizedString("About", comment: ""), items: [
                .link(text: NSLocalizedString("About", comment: ""), accessoryType: .disclosureIndicator, action: { [weak self] in
                        self?.performSegue(withIdentifier: "advancedShowAbout", sender: self)
                    })
                ])
        ]
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.estimatedRowHeight = 50

        tableView.registerReusableCell(TextFieldTableViewCell.self)
        tableView.registerReusableCell(CheckmarkTableViewCell.self)
        tableView.registerReusableCell(UITableViewCell.self)
        tableView.registerReusableCell(SwitchTableViewCell.self)
    }

    private func setupUI() {
        let logoImage = UIImage(named: "logoBlueTransparent")
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)

        let advancedLabel = UILabel(frame: CGRect(x: 40, y: 0, width: 100, height: 40))
        advancedLabel.text = "dvanced"
        advancedLabel.textColor = Constants.Color.automatBlue
        advancedLabel.font = .systemFont(ofSize: 25)

        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 140, height: 40))
        customView.addSubview(logoImageView)
        customView.addSubview(advancedLabel)

        navigationItem.titleView = customView

        formViewLayout = FormViewLayout(view: view, contentView: tableView)
        formViewLayout?.contentViewMargin = 0.0
        formViewLayout?.setupConstraints()
    }
}

extension AdvancedLoginViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cellSelector.selectCell(cell)
        }
        tableView.deselectRow(at: indexPath, animated: true)

        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case .checkmark(_, _, _, _, let action):
            action()
        case .link(_, _, _, let action):
            action()
        default:
            break
        }
    }
}

extension AdvancedLoginViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .textField(let text, let placeholder, action: _):
            let cell: TextFieldTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.titleLabel.text = text
            cell.textField.placeholder = placeholder
            cell.textField.delegate = self
            switch indexPath.section {
            case SectionType.general.rawValue:
                switch indexPath.row {
                case 0:
                    cell.textField.text = String(dependencyProvider.credentials.advanced.port)
                case 1:
                    cell.textField.text = String(dependencyProvider.credentials.advanced.localPort)
                case 2:
                    cell.textField.text = dependencyProvider.credentials.advanced.outboundServer
                case 3:
                    cell.textField.text = String(dependencyProvider.credentials.advanced.outboundPort)
                case 4:
                    cell.textField.text = dependencyProvider.credentials.advanced.authName
                case 5:
                    cell.textField.text = dependencyProvider.credentials.advanced.displayName

                default:
                    break
                }
            case SectionType.stun.rawValue:
                switch indexPath.row {
                case 0:
                    cell.textField.text = dependencyProvider.credentials.advanced.stunServer
                case 1:
                    cell.textField.text = String(dependencyProvider.credentials.advanced.stunPort)
                default:
                    break
                }
            default:
                break
            }
            return cell
        case .checkmark(let text, let accessoryType, let transport, srtp: _, action: _):
            let cell: CheckmarkTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textLabel?.text = text
            cell.accessoryType = accessoryType
            cellSelector.append(cell)
            if transport == dependencyProvider.credentials.advanced.transport {
                cellSelector.selectCell(cell)
            }
            return cell
        case .link(let text, _, let accessoryType, action: _):
            let cell: UITableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textLabel?.text = text
            cell.accessoryType = accessoryType
            return cell
        case .toggle(let dataSource):
            let cell: SwitchTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.dataSource = dataSource
            cell.toggleColor = Constants.Color.automatBlue
            return cell
        default:
            let cell: UITableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Unknown cell", comment: "")
            return cell
        }
    }
}

extension AdvancedLoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        var point = tableView.convert(textField.center, from: textField)
        point.x = 0

        guard let indexPath = tableView.indexPathForRow(at: point) else {
            return
        }

        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .textField(_, _, let action):
            action(textField.text ?? "")
        default:
            break
        }
    }
}
