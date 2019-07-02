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
import CocoaLumberjack

class SettingsViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var formViewLayout: FormViewLayout?
    private let cellSelector = CellSelector()

    private enum SectionType: Int {
        case audioCodecs
        case videoCodecs
        case srtp
        case account
    }

    private var sections: [Section] = [Section]()
    private var selectedCodecs: [Codec] = [Codec]()
    private var selectedAudioCodecs: [Codec] {
        return selectedCodecs.filter { $0.type == .audio }
    }
    private var selectedVideoCodecs: [Codec] {
        return selectedCodecs.filter { $0.type == .video }
    }
    private var selectedSRTPOption: SRTP?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableView()
        setupSections()
        loadSettings()
    }

    private func saveSettings() {
        dependencyProvider.settings.codecs = selectedCodecs
        dependencyProvider.settings.srtpOptions = selectedSRTPOption
        dependencyProvider.settings.save()
        dependencyProvider.reloadSettings()
    }

    private func loadSettings() {
        selectedCodecs = dependencyProvider.settings.codecs
        selectedSRTPOption = dependencyProvider.settings.srtpOptions
    }

    private func setupSections() {
        var audioCodecItems: [Item] = [Item]()
        var videoCodecItems: [Item] = [Item]()
        var srtpOptionItems: [Item] = [Item]()
        if let audioCodecs = dependencyProvider.voipManager.audioCodecs {
            for audioCodec in audioCodecs {
                let item: Item = .checkmark(text: audioCodec.name, accessoryType: .none, transport: nil, srtp: nil) { [weak self] in
                    DDLogInfo("Selected \(audioCodec.name)")
                    if (self?.selectedCodecs.contains(audioCodec))! {
                        let index = self?.selectedCodecs.firstIndex(of: audioCodec)
                        self?.selectedCodecs.remove(at: index!)
                    } else {
                        self?.selectedCodecs.append(audioCodec)
                    }
                }
                audioCodecItems.append(item)
            }
        }

        if let videoCodecs = dependencyProvider.voipManager.videoCodecs {
            for videoCodec in videoCodecs {
                let item: Item = .checkmark(text: videoCodec.name, accessoryType: .none, transport: nil, srtp: nil) { [weak self] in
                    DDLogInfo("Selected \(videoCodec.name)")
                    if (self?.selectedCodecs.contains(videoCodec))! {
                        let index = self?.selectedCodecs.firstIndex(of: videoCodec)
                        self?.selectedCodecs.remove(at: index!)
                    } else {
                        self?.selectedCodecs.append(videoCodec)
                    }
                }
                videoCodecItems.append(item)
            }
        }

        if let srtpOptions = dependencyProvider.voipManager.srtpOptions {
            for srtpOption in srtpOptions {
                let accessoryType: UITableViewCell.AccessoryType = srtpOption.type == .none ? .checkmark : .none
                let item: Item = .checkmark(text: srtpOption.name, accessoryType: accessoryType, transport: nil, srtp: srtpOption.type) { [weak self] in
                    DDLogInfo("Selected \(srtpOption.name)")
                    //self?.dependencyProvider.settings...
                    self?.selectedSRTPOption = srtpOption
                }
                srtpOptionItems.append(item)
            }
        }

        sections = [
            Section(title: NSLocalizedString("Audio Codecs", comment: ""), items: audioCodecItems),
            Section(title: NSLocalizedString("Video Codecs", comment: ""), items: videoCodecItems),
            Section(title: NSLocalizedString("SRTP", comment: ""), items: srtpOptionItems),
            Section(title: String(format: NSLocalizedString("Account - %@", comment: ""), dependencyProvider.credentials.login ?? ""), items: [
                .link(text: NSLocalizedString("Logout", comment: ""), action: { [weak self] in
                    self?.logout()
                })
                ])
        ]
    }

    private func setupUI() {
        formViewLayout = FormViewLayout(view: view, contentView: tableView)
        formViewLayout?.contentViewMargin = 0.0
        formViewLayout?.setupConstraints()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.registerReusableCell(TextFieldTableViewCell.self)
        tableView.registerReusableCell(CheckmarkTableViewCell.self)
        tableView.registerReusableCell(UITableViewCell.self)
        tableView.registerReusableCell(SwitchTableViewCell.self)
    }

    private func logout() {
        AlertHelper.showLogoutConfirmation(on: self) { [weak self] in
            self?.dependencyProvider.logout {
                self?.performSegue(withIdentifier: "showLogin", sender: self)
            }
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .checkmark(_, var accessoryType, _, _, let action):
            if let cell = tableView.cellForRow(at: indexPath) {
                switch indexPath.section {
                case SectionType.audioCodecs.rawValue,
                     SectionType.videoCodecs.rawValue:
                        accessoryType = cell.accessoryType == .none ? .checkmark : .none
                        cell.accessoryType = accessoryType
                case SectionType.srtp.rawValue:
                    cellSelector.selectCell(cell)
                default:
                    break
                }
            }
            action()
            saveSettings()
        case .link(_, let action):
            action()
        default:
            break
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .checkmark(let text, let accessoryType, transport: _, let srtp, action: _):
            let cell: CheckmarkTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textLabel?.text = text
            cell.backgroundColor = Constants.Color.automatBlue
            cell.textLabel?.textColor = .white
            cell.tintColor = .white
            var selected: [Codec] = [Codec]()
            switch indexPath.section {
            case SectionType.audioCodecs.rawValue:
                selected = selectedAudioCodecs.filter { $0.name == text }
                cell.accessoryType = selected.isEmpty ? .none : .checkmark
            case SectionType.videoCodecs.rawValue:
                selected = selectedVideoCodecs.filter { $0.name == text }
                cell.accessoryType = selected.isEmpty ? .none : .checkmark
            case SectionType.srtp.rawValue:
                cellSelector.append(cell)
                cell.accessoryType = accessoryType
                if let selectedSRTPOption = selectedSRTPOption,
                    let srtp = srtp {
                        if selectedSRTPOption.type == srtp {
                            cellSelector.selectCell(cell)
                        }
                }
            default:
                break
            }
            return cell
        default:
            let cell: UITableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Logout", comment: "")
            cell.backgroundColor = Constants.Color.automatBlue
            cell.textLabel?.textColor = .white

            return cell
        }
    }
}
