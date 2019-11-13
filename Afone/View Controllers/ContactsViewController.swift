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
import Contacts
import CocoaLumberjack

class ContactsViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var embeddingStackView: UIStackView!
    @IBOutlet private weak var emptyContactsLabel: UILabel!
    @IBOutlet private weak var openSettingsButton: UIButton!

    private var sections = [Section]()
    private var contacts = [Contact]()
    private var filteredContacts = [Contact]()
    private var contactsWithSections = [[Contact]]()
    private let collation = UILocalizedIndexedCollation.current()
    private var sectionTitles = [String]()
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fixes black screen when going to another tab while searching
        definesPresentationContext = true

        setupEmptyContactsView()
        setupContacts()
    }

    private func setupContacts() {
        if Permissions.isContactPermissionNotDetermined {
            Permissions.requestContactPermission { [weak self] (granted, _) in
                DispatchQueue.main.async {
                    if granted {
                        self?.getContacts()
                    } else {
                        self?.enableEmptyView(true)
                    }
                }
            }
        } else if Permissions.isContactPermissionAuthorized {
            getContacts()
        } else {
            enableEmptyView(true)
        }
    }

    private func getContacts() {
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactOrganizationNameKey,
            CNContactPhoneNumbersKey
        ]

        let store = CNContactStore()
        var contacts = [CNContact]()
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        fetchRequest.sortOrder = .userDefault
        do {
            try store.enumerateContacts(with: fetchRequest, usingBlock: { (cncontact, _) in
                contacts.append(cncontact)
            })
        } catch {
            DDLogError("Error fetching contacts \(error)")
        }

        for cncontact in contacts {
            let phoneNumbers: [String] = cncontact.phoneNumbers.map({
                let phoneNumber: CNPhoneNumber = $0.value
                return phoneNumber.stringValue
            })

            if !phoneNumbers.isEmpty {
                let contact = Contact(givenName: cncontact.givenName,
                                      familyName: cncontact.familyName,
                                      organizationName: cncontact.organizationName,
                                      phoneNumbers: phoneNumbers
                )
                self.contacts.append(contact)
            }
        }

        setupCollation()
        setupSections()
        setupTableView()
    }

    private func setupCollation() {
        let (contacts, titles) = collation.partitionObjects(array: self.contacts, collationStringSelector: #selector(getter: Contact.sortOrder))
        contactsWithSections = contacts as! [[Contact]]
        sectionTitles = titles
    }

    private func setupSections() {
        sections.removeAll()

        if searchController.isActive {
            let items: [Item] = filteredContacts.map({ contact in
                let title = contact.mainDescription
                let subtitle = contact.secondaryDescription

                return .link(text: title, detailText: subtitle, accessoryType: .none, action: { [weak self] in
                    self?.showNumbersToCall(phoneNumbers: contact.phoneNumbers)
                })
            })

            sections = [Section(title: "", items: items)]
            return
        }

        for section in sectionTitles {
            if let index = sectionTitles.firstIndex(of: section) {
                let contactsAtIndex = contactsWithSections[index]
                let items: [Item] = contactsAtIndex.map({ contact in
                    let title = contact.mainDescription
                    let subtitle = contact.secondaryDescription

                    return .link(text: title, detailText: subtitle, accessoryType: .none, action: { [weak self] in
                        self?.showNumbersToCall(phoneNumbers: contact.phoneNumbers)
                    })
                })

                sections.append(Section(title: section, items: items))
            }
        }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .clear

        tableView.registerReusableCell(SubtitleTableViewCell.self)

        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.barStyle = .blackTranslucent
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.barTintColor = .clear
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.textColor = .white
        }
        searchController.searchBar.sizeToFit()

        tableView.tableHeaderView = searchController.searchBar

        // Fixes white background under searchbar when tableView bounces
        let emptyView = UIView(frame: tableView.bounds)
        emptyView.backgroundColor = .clear
        tableView.backgroundView = emptyView

        tableView.reloadData()
    }

    private func showNumbersToCall(phoneNumbers: [String]) {
        AlertHelper.showPhoneNumberSheet(on: self, phoneNumbers: phoneNumbers) { [weak self] phoneNumber in
            self?.createCall(to: phoneNumber)
        }
    }
}

// MARK: Empty contacts view
extension ContactsViewController {
    @IBAction private func openSettings() {
        AlertHelper.openSettings()
    }

    private func setupEmptyContactsView() {
        emptyContactsLabel.text = NSLocalizedString("""
            In order to show a list of your contacts you need to grant //afone access to your contacts.
            Please go to Settings to do so.
            """, comment: "")
        openSettingsButton.configureWithBackgroundColor(Constants.Color.automatLightBlue, highlightedColor: Constants.Color.automatBlue, disabledColor: .gray, cornerRadius: 8.0)
        openSettingsButton.setTitle(NSLocalizedString("Open Settings", comment: ""), for: .normal)
    }

    private func enableEmptyView(_ enable: Bool) {
        tableView.isHidden = enable
        embeddingStackView.isHidden = !enable
    }
}

// MARK: Calling
extension ContactsViewController {
    private func createCall(to: String) {
        Permissions.requestCallPermissions([.audio, .video]) { [weak self] (accessGranted) in
            guard accessGranted else {
                    DispatchQueue.main.async {
                        if !accessGranted {
                            AlertHelper.showPermissionsAlert(on: self)
                        }
                    }
                    return
            }

            guard self?.dependencyProvider.areAudioCodecsEmpty == false else {
                DispatchQueue.main.async {
                    AlertHelper.showNoCodecsAlert(on: self)
                }
                return
            }

            let normalizedTo = PhoneNumberNormalizer.cleanupString(to, fromCharacters: "/ ()-")

            self?.dependencyProvider.calling.createCall(to: normalizedTo, hasVideo: false, completion: nil)
        }
    }
}

// MARK: UITableViewDelegate
extension ContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .link(_, _, _, let action):
            action()
        default:
            break
        }

    }
}

// MARK: UITableViewDataSource
extension ContactsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return searchController.isActive ? 1 : sectionTitles.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return searchController.isActive ? "" : sectionTitles[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var searchSign = [UITableView.indexSearch]
        searchSign.append(contentsOf: collation.sectionTitles)
        return searchSign
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0,
            let headerView = tableView.tableHeaderView {
                tableView.scrollRectToVisible(headerView.frame, animated: false)
        }
        return collation.section(forSectionIndexTitle: index) - 1 // -1 because of UITableView.indexSearch
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredContacts.count : sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case .link(let text, let detailText, _, action: _):
            let cell: SubtitleTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.backgroundColor = .clear
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .white
            cell.tintColor = .white
            cell.textLabel?.text = text
            cell.detailTextLabel?.text = detailText

            return cell
        default:
            let cell: SubtitleTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Unknown cell", comment: "")
            cell.backgroundColor = .clear
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .white

            return cell
        }
    }
}

// MARK: Search
extension ContactsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filteredContacts.removeAll()
        guard let searchText = searchController.searchBar.text else {
            return
        }
        filteredContacts = contacts.filter({ (contact) -> Bool in
            contact.mainDescription.contains(searchText)
        })

        setupSections()
        tableView.reloadData()
    }
}
