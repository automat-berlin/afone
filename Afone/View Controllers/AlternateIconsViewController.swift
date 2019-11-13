//
// Afone
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
import CocoaLumberjack

class AlternateIconsViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var sections = [Section]()
    private let cellSelector = CellSelector()
    private var appIcon: Int = 0

    private enum AppIconType: Int {
        case appIconDefault = 0
        case appIconWhite
        case appIconBlack
    }

    private enum AppIconName: String {
        case appIconDefault = "AppIcon"
        case appIconWhite = "AppIconWhite"
        case appIconBlack = "AppIconBlack"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupSections()
    }

    private func setupSections() {
        sections = [
            Section(title: NSLocalizedString("", comment: ""), items: [
                .imageCheckmark(text: nil, accessoryType: .none, image: UIImage(named: AppIconName.appIconDefault.rawValue), action: { [weak self] in
                    self?.changeAppIcon(to: nil)
                }),
                .imageCheckmark(text: nil, accessoryType: .none, image: UIImage(named: AppIconName.appIconWhite.rawValue), action: { [weak self] in
                    self?.changeAppIcon(to: AppIconName.appIconWhite.rawValue)
                }),
                .imageCheckmark(text: nil, accessoryType: .none, image: UIImage(named: AppIconName.appIconBlack.rawValue), action: { [weak self] in
                    self?.changeAppIcon(to: AppIconName.appIconBlack.rawValue)
                })
                ])
        ]
    }

    private func changeAppIcon(to: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            DDLogInfo("Supports app icon switching")
            return
        }

        UIApplication.shared.setAlternateIconName(to) { (error) in
            if error != nil {
                DDLogError("Couldn't change app icon to \(String(describing: to))")
            }
        }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .clear

        tableView.registerReusableCell(CheckmarkTableViewCell.self)
        tableView.registerReusableCell(UITableViewCell.self)
    }

    private func saveSettings() {
        dependencyProvider.settings.appIcon = appIcon
        dependencyProvider.settings.save()
    }
}

extension AlternateIconsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .imageCheckmark(_, _, _, let action):
            if let cell = tableView.cellForRow(at: indexPath) {
                cellSelector.selectCell(cell)
            }
            action()
            appIcon = indexPath.row
            saveSettings()
            navigationController?.popViewController(animated: true)
        default:
            break
        }
    }
}

extension AlternateIconsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .imageCheckmark(_, _, let image, action: _):
            let cell: CheckmarkTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.backgroundColor = .clear
            cell.textLabel?.textColor = .white
            cell.tintColor = .white
            cell.imageView?.clipsToBounds = true
            cell.imageView?.layer.cornerRadius = 12

            cellSelector.append(cell)

            var selected: Int = dependencyProvider.settings.appIcon
            if let appIconName = UIApplication.shared.alternateIconName {
                if appIconName == AppIconName.appIconWhite.rawValue {
                    selected = AppIconType.appIconWhite.rawValue
                } else if appIconName == AppIconName.appIconBlack.rawValue {
                    selected = AppIconType.appIconBlack.rawValue
                }
            }
            switch indexPath.row {
            case AppIconType.appIconDefault.rawValue:
                cell.accessoryType = selected == indexPath.row ? .checkmark : .none
                cell.imageView?.image = image
                cell.imageView?.layer.borderColor = UIColor.white.cgColor
                cell.imageView?.layer.borderWidth = 2
            default:
                cell.accessoryType = selected == indexPath.row ? .checkmark : .none
                cell.imageView?.image = image
            }
            return cell
        default:
            let cell: UITableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Unknown cell", comment: "")
            cell.backgroundColor = .clear
            cell.textLabel?.textColor = .white

            return cell
        }
    }
}
